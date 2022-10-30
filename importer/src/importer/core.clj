(ns importer.core
  (:gen-class)
  (:require [clojure.xml :as xml]
            [clojure.java.io :as io]
            [java-time.api :as jt]
            [clj-yaml.core :as yaml]
            [clojure.core.match :refer [match]]
            [slugger.core :refer [->slug]]
            [hickory.core :as hickory]
            [clojure.string :as str]))


;; Data traversal

(defn vector-find [pred arr]
  (->> arr
       (filter pred)
       first))

(defn get-children [tag el]
  (->> el
       :content
       (filter #(= (:tag %) tag))))

(defn get-tag-text [tag item-xml]
  (->> item-xml
       (get-children tag)
       first
       :content
       first))

(defn get-taxonomy [domain item-xml]
  (->> item-xml
       :content
       (filter (fn [el] (and (= (:tag el)
                                :category)
                             (= (->> el :attrs :domain)
                                domain))))
       (map (fn [el]
              {:name (->> el :content first)
               :slug (:nicename (:attrs el))}))))


;; Conversion

(defn parse-date [date-str]
  (let [date (jt/local-date-time "yyyy-MM-dd HH:mm:ss"
                                 date-str)
        get #(-> %
                 (jt/format date)
                 Integer/parseInt)]
    {:year (get "yyyy")
     :month (get "MM")
     :date (get "dd")
     :hour (get "HH")
     :minutes (get "mm")}))

(defn post-xml->post [post-xml]
  (let [title (get-tag-text :title post-xml)]
    {:title title
     :id (get-tag-text :wp:post_id post-xml)
     :slug (or (get-tag-text :wp:post_name post-xml)
               (->slug title))
     :url (get-tag-text :link post-xml)
     :date (parse-date (get-tag-text :wp:post_date post-xml))
     :categories (get-taxonomy "category" post-xml)
     :tags (get-taxonomy "post_tag" post-xml)
     :parent (get-tag-text :wp:post_parent post-xml)
     :post-type (get-tag-text :wp:post_type post-xml)
     :status (get-tag-text :wp:status post-xml)
     :content (get-tag-text :content:encoded post-xml)
     :description (get-tag-text :description post-xml)
     :excerpt (get-tag-text :excerpt:encoded post-xml)}))

(defn data->yaml [data]
  (yaml/generate-string
   data
   :dumper-options {:flow-style :block}))

(defn post->string [post]
  (let [frontmatter-data {:title (:title post)
                          :categories (->> post :categories (map :slug))
                          :tags (->> post :tags (map :slug))}]
    (str "---\n"
         (data->yaml frontmatter-data)
         "---\n\n"
         (:content post)
         "\n")))

(defn post->path [post]
  (let [status (:status post)]
    (str (if (= status "draft")
           "drafts/"
           (str (-> post :date :year) "/"
                (-> post :date :month) "-"))
         (:slug post)
         (if (= status "private")
           "-HIDDEN"
           "")
         ".md")))

(defn output-post [post]
  (let [filename (str "../data/posts/" (post->path post))]
    (io/make-parents filename)
    (spit filename (post->string post))))


;; Markdown generation

(defn h*-tag? [tag]
  (if (and tag
           (re-matches #"(?i)^h\d$" (name tag)))
    true
    false))

(defn em->md [el]
  (str "_"
       (->> el :content els->md)
       "_"))

(defn img->md [el]
  (let [alt (->> el :attrs :alt)
        title (->> el :attrs :title)]
    (str "!["
         (if (or (not alt) (= alt ""))
           "image"
           alt)
         "]("
         (->> el :attrs :src)
         (if title
           (str " \"" title "\"")
           "")
         ")")))

(defn a->md [el]
  (str "["
       (->> el :content els->md)
       "]("
       (->> el :attrs :href)
       ")"))

(defn h*->md [el]
  (let [n (match [(:tag el)]
            [:h1] 1
            [:h2] 2
            [:h3] 3
            [:h4] 4
            [:h5] 5)]
    (str "\n"
         (apply str (repeat n "="))
         " "
         (->> el :content first el->md)
         "\n")))

(defn div->md [el]
  (if (= (->> el :attrs :class)
         "language")
    (str "\n"
         "---\n\n"
         "<!-- language -->\n\n"
         (->> el :content els->md))
    (->> el :content els->md)))

(defn span->md [el]
  (cond
    (->> el :attrs :style (= "font-style: italic;")) (em->md el)
    (->> el :attrs :class (= "postbody")) (->> el :content els->md)
    :else "???"))

(defn blockquote->md [el]
  (let [parsed-content (->> el :content els->md)]
    (str "\n"
         (->> parsed-content
              str/split-lines
              (map #(str "> " %))
              (str/join "\n"))
         "\n")))

(defn vimeo-el->video [el]
  (let [width (->> el :attrs :width)
        height (->> el :attrs :height)
        id (->> el
                (get-children :param)
                (vector-find #(= (->> % :attrs :name)
                                 "src"))
                :attrs
                :value
                (re-matches #".*clip_id=(\d+).*")
                (#(nth % 1)))]
    {:service "vimeo"
     :id id
     :width width
     :height height}))

(defn vimeo-el? [el]
  (and (= (:tag el)
          :object)
       (some->> el
                (get-children :param)
                (vector-find #(= (->> % :attrs :name)
                                 "src"))
                :attrs
                :value
                (re-matches #".*vimeo.*"))))

(defn el->video [el]
  (cond
    (vimeo-el? el) (vimeo-el->video el)
    :else nil))

(defn video->md [video]
  (str "<VideoEmbed "
       "service=\"" (:service video) "\" "
       "id=\"" (:id video) "\" "
       "width=\"" (:width video) "\" "
       "height=\"" (:height video) "\" "
       "/>"))

(defn el->md [el]
  (match [(:tag el) (:type el)]
    [:em _] (em->md el)
    [:a _] (a->md el)
    [:img _] (img->md el)
    [:ul _]  (->> el :content els->md)
    [:li _] (str "- "
                 (->> el :content els->md))
    [:blockquote _] (blockquote->md el)
    [:div _] (div->md el)
    [:span _] (span->md el)
    [_ :comment] (str "<!-- "
                      (->> el :content els->md)
                      " -->")
    [nil nil] el
    :else (cond
            (h*-tag? (:tag el)) (h*->md el)
            (el->video el) (video->md (el->video el))
            :else "???")))

(defn els->md [els]
  (->> els (map el->md) (apply str)))


;; Data

(def wordpress-xml (-> "wordpress-data.xml"
                       io/resource
                       io/file
                       xml/parse))

(def items-xml (->> wordpress-xml
                    :content
                    first
                    :content
                    (filter (fn [el]
                              (and (= (:tag el)
                                      :item)
                                   (= (:tag (first (:content el)))
                                      :title))))))

(def posts-xml (->> items-xml
                    (filter (fn [item-xml]
                              (= (get-tag-text :wp:post_type item-xml)
                                 "post")))))

(def posts (map post-xml->post posts-xml))


;; Main

(defn -main
  "Generate blog data from Wordpress XML export file."
  [& args]

  (println (str "Current directory: "
                (System/getProperty "user.dir")))
;;   (println (map post->path posts))

  (doseq [post posts]
    (output-post post)))



(comment
  (println
   (->> posts-xml
        (#(nth % 6))
        post-xml->post
        :content
        hickory/parse-fragment
        (map hickory/as-hickory)
        els->md
        ;;
        )
   ;;
   )

  (->>
   "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" width=\"500\" height=\"333\" codebase=\"http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,40,0\">
       <param name=\"allowfullscreen\" value=\"true\" />
       <param name=\"allowscriptaccess\" value=\"always\" />
       <param name=\"src\" value=\"http://vimeo.com/moogaloop.swf?clip_id=1260271&amp;server=vimeo.com&amp;show_title=0&amp;show_byline=0&amp;show_portrait=0&amp;color=ffffff&amp;fullscreen=1\" />
       <embed type=\"application/x-shockwave-flash\" width=\"500\" height=\"333\" src=\"http://vimeo.com/moogaloop.swf?clip_id=1260271&amp;server=vimeo.com&amp;show_title=0&amp;show_byline=0&amp;show_portrait=0&amp;color=ffffff&amp;fullscreen=1\" allowscriptaccess=\"always\" allowfullscreen=\"true\"></embed>
     </object>"
   hickory/parse-fragment
   (map hickory/as-hickory)
   first
   object->video)

  (last posts)
  ;;
  )