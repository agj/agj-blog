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

(declare els->md
         el->md)


;; Utilities

(defn leftpad [char length target]
  (cond
    (number? target) (leftpad char length (str target))
    (string? target) (apply str (concat (take (- length (count target))
                                              (repeat char))
                                        target))))


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
     :content (or (get-tag-text :content:encoded post-xml)
                  "\n")
     :description (get-tag-text :description post-xml)
     :excerpt (get-tag-text :excerpt:encoded post-xml)}))

(defn data->yaml [data]
  (yaml/generate-string
   data
   :dumper-options {:flow-style :block}))


;; Markdown generation

(defn surround->md [before after el]
  (str before
       (->> el :content els->md)
       after))

(defn h*-tag? [tag]
  (if (and tag
           (re-matches #"(?i)^h\d$" (name tag)))
    true
    false))

(defn em->md [el]
  (surround->md "_" "_" el))

(defn strong->md [el]
  (surround->md "**" "**" el))

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
         (apply str (repeat n "#"))
         " "
         (->> el :content first el->md)
         "\n")))

(defn div->md [el]
  (if (= (->> el :attrs :class)
         "language")
    (str "\n"
         "<language-break />\n\n"
         (->> el :content els->md))
    (->> el :content els->md)))

(defn span->md [el]
  (cond
    (->> el :attrs :style (= "font-style: italic;")) (em->md el)
    (->> el :attrs :class (= "postbody")) (->> el :content els->md)
    (->> el :attrs :class (= "s1")) (->> el :content els->md)
    :else "???"))

(defn blockquote->md [el]
  (let [parsed-content (->> el :content els->md)]
    (str "\n"
         (->> parsed-content
              str/split-lines
              (map #(str "> " %))
              (str/join "\n"))
         "\n")))

(defn ol->md [el]
  (->> el
       :content
       (reduce (fn [result-count el]
                 (let [result (first result-count)
                       count (second result-count)]
                   (if (= (:tag el) :li)
                     [(conj result
                            (str (inc count) ". "
                                 (->> el :content els->md)))
                      (inc count)]
                     [(conj result (el->md el))
                      count])))
               [[] 0])
       first
       (apply str)))

(defn ul->md [el]
  (->> el
       :content
       (map (fn [el]
              (if (= (:tag el)
                     :li)
                (str "- "
                     (->> el :content els->md))
                (el->md el))))
       (apply str)))

(defn video-el->url [el]
  (match [(:tag el)]
    [:iframe] (->> el :attrs :src)
    [:object] (some->> el
                       (get-children :param)
                       (vector-find #(let [name (->> % :attrs :name)]
                                       (or (= name "src")
                                           (= name "movie"))))
                       :attrs
                       :value)
    :else nil))

(defn vimeo-el? [el]
  (boolean
   (->> el
        video-el->url
        (re-matches #".*vimeo.*"))))

(defn youtube-el? [el]
  (boolean
   (->> el
        video-el->url
        (re-matches #".*youtube.*"))))

(defn vimeo-el->video [el]
  (let [id (->> el
                video-el->url
                (re-matches #".*(clip_id=|video\/)(\d+).*")
                (#(nth % 2)))]
    {:service "vimeo"
     :id id
     :width (->> el :attrs :width)
     :height (->> el :attrs :height)}))

(defn youtube-el->video [el]
  (let [id (->> el
                video-el->url
                (re-matches #".*(embed\/)([^?]+).*")
                (#(nth % 2)))]
    {:service "youtube"
     :id id
     :width (->> el :attrs :width)
     :height (->> el :attrs :height)}))

(defn el->video [el]
  (cond
    (vimeo-el? el) (vimeo-el->video el)
    (youtube-el? el) (youtube-el->video el)
    :else nil))

(defn video->md [video]
  (str "<video-embed "
       "service=\"" (:service video) "\" "
       "id=\"" (:id video) "\" "
       "width=\"" (:width video) "\" "
       "height=\"" (:height video) "\" "
       "/>"))

(defn el->md [el]
  (match [(:tag el) (:type el)]
    [:em _] (em->md el)
    [:strong _] (strong->md el)
    [:a _] (a->md el)
    [:img _] (img->md el)
    [:ul _]  (ul->md el)
    [:ol _] (ol->md el)
    [:blockquote _] (blockquote->md el)
    [:del _] (surround->md "~~" "~~" el)
    [:div _] (div->md el)
    [:span _] (span->md el)
    [:pre _] (surround->md "```\n" "\n```" el)
    [_ :comment] (surround->md "<!-- " " -->" el)
    [nil nil] el
    :else (cond
            (h*-tag? (:tag el)) (h*->md el)
            (el->video el) (video->md (el->video el))
            :else "???")))

(defn els->md [els]
  (->> els (map el->md) (apply str)))

(defn post-content->md [content]
  (->> content
       hickory/parse-fragment
       (map hickory/as-hickory)
       els->md
       str/trim
       (#(str/replace % #"\n\n\n+" "\n\n"))))


;; Final processing

(defn post->string [post]
  (let [frontmatter-data {:id (Integer/parseInt (:id post))
                          :title (:title post)
                          :date (->> post :date :date)
                          :hour (->> post :date :hour)
                          :categories (->> post :categories (map :slug))
                          :tags (->> post :tags (map :slug))}]
    (str "---\n"
         (data->yaml frontmatter-data)
         "---\n\n"
         (->> post :content post-content->md)
         "\n")))

(defn post->path [post]
  (let [status (:status post)]
    (str (if (= status "draft")
           "drafts/"
           (str (->> post :date :year) "/"
                (->> post :date :month (leftpad \0 2)) "-"))
         (:slug post)
         (if (= status "private")
           "-HIDDEN"
           "")
         ".md")))

(defn output-post [post]
  (let [filename (str "../data/posts/" (post->path post))]
    (io/make-parents filename)
    (spit filename (post->string post))))


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
     ;;    (#(nth % 10))
        (map post-xml->post)
        (vector-find #(= (:id %) "31"))
        :content
        post-content->md
        ;;
        )
   ;;
   )

  (println
   (->>
    "<iframe width=\"500\" height=\"281\" src=\"//www.youtube.com/embed/6Oiq0rH9_SI?rel=0\" frameborder=\"0\" allowfullscreen></iframe>"
    hickory/parse-fragment
    (map hickory/as-hickory)
    first
    vimeo-el?)
   ;;
   )

  (println
   (->> ["http://blog.agj.cl/2009/01/campodecolor-got-me-out-of-college/#more-118"
         "http://www.agj.cl/files/games/campodecolor_memoria.pdf"
         "http://blog.agj.cl/wp-content/uploads/2009/04/heartlogo1.png"
         "http://piclog.agj.cl/?picture=89"]
        (map (fn [url]
               (let [blog-match (re-matches #".*://blog[.]agj[.]cl(.*)" url)
                     agj-cl-match (re-matches #".*:(//.*[.]agj[.]cl.*)" url)
                     wp-content-match (re-matches #".*://blog[.]agj[.]cl/wp-content/uploads/(\d+)/(\d+)/(.*)" url)]
                 (or (if wp-content-match
                       (str "/blog.agj.cl/files/"
                            (get wp-content-match 1) "/"
                            (get wp-content-match 2) "-"
                            (get wp-content-match 3))
                       nil)
                     (let [blog-url (get blog-match 1)]
                       (if blog-url
                         (str/replace blog-url #"#more-\d+" "#language")
                         nil))
                     (get agj-cl-match 1)
                     url))))
        (str/join "\n")))

  ;;
  )