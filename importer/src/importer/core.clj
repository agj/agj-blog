(ns importer.core
  (:gen-class) 
  (:require [clojure.xml :as xml]
            [clojure.java.io :as io]
            [clojure.zip :as z]))

(require '[clojure.zip :as z]
         '[clojure.java.io :as io]
         '[clojure.xml :as xml])

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))

(comment
  (z/xml-zip
   (-> "wordpress-data.xml"
      io/resource
      io/file
      xml/parse))
  )
