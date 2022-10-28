#lang racket
(require xml
         "../structs/post.rkt")

(provide (contract-out
           [post->xexpr (-> post? xexpr?)]))
(define (post->xexpr post)
  `(html
     (head
       (title "agj's blog"))
     (body
       (section [(class "content")
                 (id ,(string-append "post-" (post-slug post)))]
                (h1 ,(post-title post))))))
