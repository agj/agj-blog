#lang racket
(require "category.rkt"
         "tag.rkt"
         "content-object.rkt")

(provide (contract-out
          [struct post ((categories (listof category?))
                        (tags (listof tag?)))]))
(struct post content-object (categories tags)
  #:transparent)
