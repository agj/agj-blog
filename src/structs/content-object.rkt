#lang racket
(require "content.rkt"
         "../utils.rkt")

(provide (contract-out
           [struct content-object ((title string?)
                                   (slug slug?)
                                   (date date?)
                                   (content content?))]))
(struct content-object (title slug date content)
  #transparent)
