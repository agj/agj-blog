(ns importer.core
  (:gen-class)
  (:require [clojure.xml :as xml]
            [clojure.java.io :as io]
            [hickory.core :as hickory]
            [clojure.string :as str]
            [clojure.core.match :refer [match]]
            [importer.utils :as utils]
            [importer.posts :as posts]
            [importer.taxonomy :as taxonomy]))


;; Data

(def wordpress-xml-root (-> "wordpress-data.xml"
                            io/resource
                            io/file
                            xml/parse))

(def wordpress-xml (->> wordpress-xml-root
                        :content
                        first
                        :content))


;; Main

(defn -main
  "Generate blog data from Wordpress XML export file."
  [& args]

  (let [command (first args)]
    (match [command]
      ["posts"] (posts/output-posts wordpress-xml)
      ["taxonomy"] (taxonomy/output-taxonomy wordpress-xml)
      :else (do
              (println "Run with one of the following commands to generate the corresponding blog data:")
              (println "    posts, taxonomy")))))



(comment
  (println
   (->> wordpress-xml
        :content
        first
        :content
     ;;    (#(nth % 10))
        ((fn [items-xml]
           (->> items-xml
                (filter #(= (:tag %) :wp:tag)))))
        (map)
        ;;
        )
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