(ns importer.core
  (:gen-class)
  (:require [clojure.xml :as xml]
            [clojure.java.io :as io]
            [hickory.core :as hickory]
            [clojure.string :as str]
            [importer.utils :as utils]
            [importer.posts :as posts]))


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


;; Main

(defn -main
  "Generate blog data from Wordpress XML export file."
  [& args]

  (println (str "Current directory: "
                (System/getProperty "user.dir")))
;;   (println (map post->path posts))

  (posts/output-posts items-xml))



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