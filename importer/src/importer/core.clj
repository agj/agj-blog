(ns importer.core
  (:gen-class)
  (:require [clojure.xml :as xml]
            [clojure.java.io :as io]
            [java-time.api :as jt]
            [clj-yaml.core :as yaml]
            [clojure.core.match :refer [match]]
            [slugger.core :refer [->slug]]))


;; Helpers

(defn get-tag-text [tag item-xml]
  (->> item-xml
       :content
       (filter (fn [el] (= (:tag el)
                           tag)))
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

(defn parse-post [post-xml]
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

(defn encode-yaml [data]
  (yaml/generate-string
   data
   :dumper-options {:flow-style :block}))

(defn encode-post [post]
  (let [frontmatter-data {:title (:title post)
                          :categories (->> post :categories (map :slug))
                          :tags (->> post :tags (map :slug))}]
    (str "---\n"
         (encode-yaml frontmatter-data)
         "---\n\n"
         (:content post)
         "\n")))

(defn get-post-path [post]
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

(defn write-post [post]
  (let [filename (str "../data/posts/" (get-post-path post))]
    (io/make-parents filename)
    (spit filename (encode-post post))))


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

(def posts (map parse-post posts-xml))


;; Main

(defn -main
  "Generate blog data from Wordpress XML export file."
  [& args]

  (println (str "Current directory: "
                (System/getProperty "user.dir")))
;;   (println (map get-post-path posts))

  (doseq [post posts]
    (write-post post)))



(comment
  (println
   (->> posts-xml
     ;;    last
        (map parse-post)
     ;;    (filter #(->> % :slug not))
     ;;    (map (fn [post]
     ;;           (assoc post :slug (->slug (:title post)))))
        (map get-post-path)))

  (last posts)
  ;;
  )