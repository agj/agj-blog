#lang racket

(provide (contract-out
          [struct tag ((id integer?) (name string?))]))
(struct tag (id name)
  #:transparent)
