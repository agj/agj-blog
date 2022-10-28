#lang racket

(define (slug? value)
  (and (string? value)
       (regexp-match? #rx"^[-a-z0-9]+$" value)))
