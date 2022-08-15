;; -*- lexical-binding: t; -*-
(require 'ert-async)

(intern "swift-error")

(ert-deftest swift-module:check-basic-conversion ()
  (should (eq (swift-int 10) 20))
  (should (< (abs (- 21.0 (swift-float 10.5))) 1e-6))
  (should (swift-bool nil))
  (should (not (swift-bool t))))

(ert-deftest swift-module:check-incorrect-num-of-args ()
  (should-error (swift-int) :type 'wrong-number-of-arguments)
  (should-error (swift-int 10 20) :type 'wrong-number-of-arguments))

(ert-deftest swift-module:check-incorrect-arg-type ()
  (should-error (swift-int "a") :type 'wrong-type-argument)
  (should-error (swift-int 10.5) :type 'wrong-type-argument)
  (should-error (swift-float 10) :type 'wrong-type-argument))

(ert-deftest swift-module:check-exception-on-emacs-side ()
  (should-error (swift-calls-bad-function) :type 'void-function))

(ert-deftest swift-module:check-exception-on-swift-side ()
  (should-error (swift-throws 42) :type 'swift-error)
  (should-error (swift-throws-sometimes 42) :type 'swift-error)
  (should (eq (swift-throws-sometimes 41) 41)))

(ert-deftest swift-module:check-opaquely-converted ()
  (let ((a1 (swift-create-a))
        (a2 (swift-create-a))
        (b1 (swift-create-b))
        (b2 (swift-create-b)))
    (should (eq (swift-get-a-x a1) 42))
    (should (eq (swift-get-a-x a2) 42))
    (should (equal (swift-get-a-y a1) "Hello"))
    (should (equal (swift-get-a-y a2) "Hello"))
    (swift-set-a-x a1 15)
    (swift-set-a-y a1 "Boom")
    (should-error (swift-set-a-x a1 10.0) :type 'wrong-type-argument)
    (should (eq (swift-get-a-x a1) 15))
    (should-not (eq (swift-get-a-x a1) (swift-get-a-x a2)))
    (should-error (swift-get-b-z "str") :type 'wrong-type-argument)
    (should-error (swift-get-b-z a1) :type 'wrong-type-argument)))

(ert-deftest swift-module:check-array-conversion ()
  (should (eq (swift-sum-array [0 2 10 -1]) 11))
  (should-error (swift-sum-array 10) :type 'wrong-type-argument)
  (should (equal (swift-map-array [1 2 3] (lambda (x) (* x x))) [1 4 9])))

(ert-deftest swift-module:check-optional-conversion ()
  (should (eq (swift-optional-arg 10) 10))
  (should (eq (swift-optional-arg nil) 42))
  (should (eq (swift-optional-result 10) 20))
  (should (eq (swift-optional-result 42) nil)))

(ert-deftest swift-module:check-captures ()
  (should (eq (swift-get-captured-a-x) 42))
  (swift-set-captured-a-x 15)
  (should (eq (swift-get-captured-a-x) 15)))

(ert-deftest swift-module:funcall-result-conversion ()
  (should (equal (swift-typed-funcall 42) "42"))
  (should-error (swift-incorrect-typed-funcall 42) :type 'wrong-type-argument))

(ert-deftest swift-module:check-symbol-conversion ()
  (should (equal (swift-symbol-name 'hello) "hello"))
  (should-error (swift-symbol-name 10) :type 'wrong-type-argument))

(ert-deftest swift-module:check-lambda ()
  (should (equal (swift-call-lambda "hello") "Received hello"))
  (should (equal (funcall (swift-get-lambda) "hello") "Received hello")))

(ert-deftest-async swift-module:check-async (done1 done2 done3 done4)
  (swift-async-channel done1)
  (swift-async-lisp-callback done2)
  (swift-async-lisp-callback done3)
  (swift-with-environment done4))

(ert-deftest swift-module:check-persistence ()
  (mapc (lambda (x) (swift-add-to-array x)) (number-sequence 1 5))
  (should (equal (swift-get-array) (vconcat (number-sequence 1 5)))))

(ert-deftest-async swift-module:check-async-hook (done1 done2)
  (setq normal-hook nil)
  (add-hook 'normal-hook done1)
  (setq abnormal-hook nil)
  (add-hook 'abnormal-hook (lambda (x) (when (eq x 42) (funcall done2))))
  (swift-async-normal-hook)
  (swift-async-abnormal-hook))

(ert-deftest swift-module:check-cons-conversion ()
  (should (equal (swift-cons-arg '(10 . "String")) "(10 . String)"))
  (should (equal (swift-cons-return [1 2 3 4]) [(1 . 1) (2 . 4) (3 . 9) (4 . 16)])))

(ert-deftest swift-module:check-list-conversion ()
  (should (equal (swift-list '(1 2 3 4)) '(2 4 6 8)))
  (should (equal (swift-list-length (number-sequence 1 50000)) 50000)))

(ert-deftest swift-module:check-alist-conversion ()
  (let ((result (swift-alist '((10 . "a") (42 . "matters") (43 . "b")))))
    (should (equal (length result) 1))))

(ert-deftest-async swift-module:check-async-nested-1 (done1 done2)
  (swift-async-channel-with-result
   (lambda (x)
     (swift-async-channel-with-result
      (lambda (y) (should (equal x y)) (funcall done1)))
     (swift-async-channel done2))))

(ert-deftest-async swift-module:check-async-nested-2 (done1)
  (swift-nested-async-with-result
   (lambda (x)
     (should (equal x 42))
     (funcall done1))))

(ert-deftest-async swift-module:check-async-with-result (done)
  (swift-with-async-environment
   10 (lambda (x)
        (should (equal x 32))
        (funcall done))))
