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
