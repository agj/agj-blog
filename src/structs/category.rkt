#lang racket

(provide (contract-out
          [struct category ((id integer?) (name string?))]))
(struct category (id name)
  #:transparent)
