;; -*- lexical-binding: t; -*-
(require 'ert-async)

(intern "swift-error")

;; This is a nasty hack to make ert-deftest-async accept tags.
(defmacro ert-deftest-async-tagged (name callbacks &rest tags-and-body)
  (declare (indent 2))
  (let ((tags (car (cdr (car (ert--parse-keys-and-body tags-and-body)))))
        (body (car (cdr (ert--parse-keys-and-body tags-and-body)))))
    `(progn (ert-deftest-async ,name ,callbacks ,@body)
            (setf (ert-test-tags (get ',name 'ert--test)) ,tags))))

(ert-deftest swift-module:check-basic-conversion ()
  :tags '(emacs-all)
  (should (eq (swift-int 10) 20))
  (should (< (abs (- 21.0 (swift-float 10.5))) 1e-6))
  (should (swift-bool nil))
  (should (not (swift-bool t)))
  (let ((s1 "I uncover the soul-destroying abhorrence")
        (s2 "Ξεσκεπάζω τὴν ψυχοφθόρα βδελυγμία"))
    (should (string= s1 (swift-string s1)))
    (should (string= s2 (swift-string s2)))))

(ert-deftest swift-module:check-incorrect-num-of-args ()
  :tags '(emacs-all)
  (should-error (swift-int) :type 'wrong-number-of-arguments)
  (should-error (swift-int 10 20) :type 'wrong-number-of-arguments))

(ert-deftest swift-module:check-incorrect-arg-type ()
  :tags '(emacs-all)
  (should-error (swift-int "a") :type 'wrong-type-argument)
  (should-error (swift-int 10.5) :type 'wrong-type-argument)
  (should-error (swift-float 10) :type 'wrong-type-argument))

(ert-deftest swift-module:check-exception-on-emacs-side ()
  :tags '(emacs-all)
  (should-error (swift-calls-bad-function) :type 'void-function))

(ert-deftest swift-module:check-exception-on-swift-side ()
  :tags '(emacs-all)
  (should-error (swift-throws 42) :type 'swift-error)
  (should-error (swift-throws-sometimes 42) :type 'swift-error)
  (should (eq (swift-throws-sometimes 41) 41)))

(ert-deftest swift-module:check-opaquely-converted ()
  :tags '(emacs-all)
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
  :tags '(emacs-all)
  (should (eq (swift-sum-array [0 2 10 -1]) 11))
  (should-error (swift-sum-array 10) :type 'wrong-type-argument)
  (should (equal (swift-map-array [1 2 3] (lambda (x) (* x x))) [1 4 9])))

(ert-deftest swift-module:check-optional-conversion ()
  :tags '(emacs-all)
  (should (eq (swift-optional-arg 10) 10))
  (should (eq (swift-optional-arg nil) 42))
  (should (eq (swift-optional-result 10) 20))
  (should (eq (swift-optional-result 42) nil)))

(ert-deftest swift-module:check-captures ()
  :tags '(emacs-all)
  (should (eq (swift-get-captured-a-x) 42))
  (swift-set-captured-a-x 15)
  (should (eq (swift-get-captured-a-x) 15)))

(ert-deftest swift-module:funcall-result-conversion ()
  :tags '(emacs-all)
  (should (equal (swift-typed-funcall 42) "42"))
  (should-error (swift-incorrect-typed-funcall 42) :type 'wrong-type-argument))

(ert-deftest swift-module:check-symbol-conversion ()
  :tags '(emacs-all)
  (should (equal (swift-symbol-name 'hello) "hello"))
  (should-error (swift-symbol-name 10) :type 'wrong-type-argument))

(ert-deftest swift-module:check-lambda ()
  :tags '(emacs-all)
  (should (equal (swift-call-lambda "hello") "Received hello"))
  (should (equal (funcall (swift-get-lambda) "hello") "Received hello")))

(ert-deftest-async-tagged swift-module:check-async (done1 done2 done3 done4)
  :tags '(emacs-28 emacs-29)
  (swift-async-channel done1)
  (swift-async-lisp-callback done2)
  (swift-async-lisp-callback done3)
  (swift-with-environment done4))

(ert-deftest swift-module:check-persistence ()
  :tags '(emacs-28 emacs-29)
  (mapc (lambda (x) (swift-add-to-array x)) (number-sequence 1 5))
  (should (equal (swift-get-array) (vconcat (number-sequence 1 5)))))

(ert-deftest-async-tagged swift-module:check-async-hook (done1 done2)
  :tags '(emacs-28 emacs-29)
  (setq normal-hook nil)
  (add-hook 'normal-hook done1)
  (setq abnormal-hook nil)
  (add-hook 'abnormal-hook (lambda (x) (when (eq x 42) (funcall done2))))
  (swift-async-normal-hook)
  (swift-async-abnormal-hook))

(ert-deftest swift-module:check-cons-conversion ()
  :tags '(emacs-all)
  (should (equal (swift-cons-arg '(10 . "String")) "(10 . String)"))
  (should (equal (swift-cons-return [1 2 3 4]) [(1 . 1) (2 . 4) (3 . 9) (4 . 16)])))

(ert-deftest swift-module:check-list-conversion ()
  :tags '(emacs-all)
  (should (equal (swift-list '(1 2 3 4)) '(2 4 6 8)))
  (should (equal (swift-list-length (number-sequence 1 50000)) 50000)))

(ert-deftest swift-module:check-alist-conversion ()
  :tags '(emacs-all)
  (let ((result (swift-alist '((10 . "a") (42 . "matters") (43 . "b")))))
    (should (equal (length result) 1))))

(ert-deftest-async-tagged swift-module:check-async-nested-1 (done1 done2)
  :tags '(emacs-28 emacs-29)
  (swift-async-channel-with-result
   (lambda (x)
     (swift-async-channel-with-result
      (lambda (y) (should (equal x y)) (funcall done1)))
     (swift-async-channel done2))))

(ert-deftest-async-tagged swift-module:check-async-nested-2 (done1)
  :tags '(emacs-28 emacs-29)
  (swift-nested-async-with-result
   (lambda (x)
     (should (equal x 42))
     (funcall done1))))

(ert-deftest-async-tagged swift-module:check-async-with-result (done)
  :tags '(emacs-28 emacs-29)
  (swift-with-async-environment
   10 (lambda (x)
        (should (equal x 32))
        (funcall done))))

(ert-deftest-async-tagged swift-module:lifetime-checks (done)
  :tags '(emacs-all)
  (should-error (swift-env-misuse-lifetime) :type 'swift-error)
  (swift-env-misuse-thread
   (lambda () (funcall done "Shouldn't have called the callback")))
  (funcall done))

(ert-deftest swift-module:result-conversion-error ()
  :tags '(emacs-all)
  (should-error (swift-result-conversion-error) :type 'wrong-type-argument))

(ert-deftest-async-tagged swift-module:error-in-async (done)
  :tags '(emacs-28 emacs-29)
  (swift-async-channel
   (lambda ()
     (funcall done)
     (should-error (asdagasda) :type 'void-function))))
