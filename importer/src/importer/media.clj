(ns importer.media
  (:require [clojure.java.io :as io]
            [clojure.core.match :refer [match]]
            [importer.utils :as utils]))

(defn attachment-xml->medium [attachment-xml]
  (let [url (utils/get-tag-text :wp:attachment_url attachment-xml)
        url-matches (re-matches #".*wp-content/uploads/\d+/\d+/(.*)" url)
        link (utils/get-tag-text :link attachment-xml)
        link-matches (re-matches #".*/(\d+)/(\d+)/([^/]+)/.*" link)]
    {:url url
     :year (nth link-matches 1)
     :month (nth link-matches 2)
     :filename (nth url-matches 1)
     :related-post (nth link-matches 3)}))

(defn output-single-medium [medium]
  (let [output-filename (str "../../files/"
                             (:year medium) "/"
                             (:month medium) "/"
                             (:related-post medium) "/"
                             (:filename medium))]
    (io/make-parents output-filename)
    (println (str "Output: " output-filename))
    (with-open [in (io/input-stream (:url medium))
                out (io/output-stream output-filename)]
      (io/copy in out))))


;; Main

(defn output-media [wordpress-xml]
  (let [attachment-xmls (->> wordpress-xml
                             (filter #(and (= (:tag %)
                                              :item)
                                           (= (utils/get-tag-text :wp:post_type %)
                                              "attachment"))))
        media (map attachment-xml->medium attachment-xmls)]
    (doseq [medium media]
      (output-single-medium medium))))

