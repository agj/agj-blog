(ns importer.taxonomy
  (:require [clojure.java.io :as io]
            [clj-yaml.core :as yaml]
            [clojure.core.match :refer [match]]
            [slugger.core :refer [->slug]]
            [hickory.core :as hickory]
            [clojure.string :as str]
            [importer.utils :as utils]))

(defn category-xml->category [category-xml]
  {:slug (utils/get-tag-text :wp:category_nicename category-xml)
   :name (utils/get-tag-text :wp:cat_name category-xml)
   :parent-slug (utils/get-tag-text :wp:category_parent category-xml)
   :description (utils/get-tag-text :wp:category_description category-xml)})

(defn tag-xml->tag [tag-xml]
  {:slug (utils/get-tag-text :wp:tag_slug tag-xml)
   :name (utils/get-tag-text :wp:tag_name tag-xml)})


;; Main

(defn output-taxonomy [wordpress-xml]
  (let [categories-xml (->> wordpress-xml
                            (filter #(= (:tag %) :wp:category)))
        categories (map category-xml->category categories-xml)
        tags-xml (->> wordpress-xml
                      (filter #(= (:tag %) :wp:tag)))
        tags (map tag-xml->tag tags-xml)]
    (println categories)
    (println tags)))
