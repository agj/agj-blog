(ns importer.core
  (:gen-class)
  (:require [clojure.xml :as xml]
            [clojure.java.io :as io]
            [java-time.api :as jt]))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))


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
                                 date-str)]
    {:year (jt/format "yyyy" date)
     :month (jt/format "MM" date)
     :date (jt/format "dd" date)
     :hour (jt/format "HH" date)
     :minutes (jt/format "mm" date)}))

(defn parse-post [post-xml]
  {:title (get-tag-text :title post-xml)
   :id (get-tag-text :wp:post_id post-xml)
   :slug (get-tag-text :wp:post_name post-xml)
   :url (get-tag-text :link post-xml)
   :date (parse-date (get-tag-text :wp:post_date post-xml))
   :categories (get-taxonomy "category" post-xml)
   :tags (get-taxonomy "post_tag" post-xml)
   :parent (get-tag-text :wp:post_parent post-xml)
   :post-type (get-tag-text :wp:post_type post-xml)
   :status (get-tag-text :wp:status post-xml)
   :content (get-tag-text :content:encoded post-xml)
   :description (get-tag-text :description post-xml)
   :excerpt (get-tag-text :excerpt:encoded post-xml)})


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



(comment
  (->> posts-xml
       last
       parse-post)

  (last posts)
  ;;
  )