#lang racket

(provide (contract-out
          [struct content ((data string?)
                           (format string?))]))
(struct content (data format)
  #:transparent)
