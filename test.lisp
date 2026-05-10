;(ql:quickload :cl-mpm/examples/collapse)
;(ql:quickload :cl-mpm/implicit)
;(ql:quickload :serapeum)
(in-package :cl-mpm/examples/collapse)

(defparameter *sim* nil)
(defparameter *run-sim* t)
(defparameter *t* 0)
(defparameter *sim-step* 0)

(defparameter *name* (let ((var (uiop:getenv "NAME"))) (if var var "standard")))
(defparameter *refine* (let ((var (uiop:getenv "REFINE"))) (parse-float:parse-float (if var var "1"))))
(defparameter *mps* (let ((var (uiop:getenv "MPS"))) (parse-float:parse-float (if var var "2"))))
(defparameter *threads* (let ((var (uiop:getenv "OMP_NUM_THREADS"))) (parse-integer (if var var "1"))))
(defparameter *lstps* (let ((var (uiop:getenv "LSTPS"))) (parse-integer (if var var "1"))))
(defparameter *solver* (let ((var (uiop:getenv "SOLVER"))) (if var var "DR")))
(defparameter *agg* (let ((var (uiop:getenv "AGG"))) (string= (if var var "TRUE") "TRUE")))
(defparameter *solver-hash* (serapeum:dict "DR" 'cl-mpm/dynamic-relaxation::mpm-sim-quasi-static "IMPLICIT" 'cl-mpm/implicit::mpm-sim-implicit))

(format t "Running test with settings name ~A refine ~A lstps ~A mps ~A threads ~A solver ~A agg ~A~%" *name* *refine* *lstps* *mps* *threads* *solver* *agg*)
(cl-mpm/utils::set-workers *threads*)

(declaim (notinline test))
(defun test ()
  (setup
    :refine *refine*
    :mps *mps*)
  (cl-mpm::domain-sort-mps *sim*)
  (format t "Changing class ~A~%" (gethash *solver* *solver-hash*))
  (change-class *sim* (gethash *solver* *solver-hash*))

  (cl-mpm:iterate-over-mps
   (cl-mpm:sim-mps *sim*)
   (lambda (mp)
     (change-class mp 'cl-mpm/particle::particle-vm)))

  (setf lparallel:*debug-tasks-p* nil)

  (setf (cl-mpm/aggregate::sim-enable-aggregate *sim*) *agg*
      (cl-mpm::sim-ghost-factor *sim*) nil
      (cl-mpm::sim-enable-fbar *sim*) nil)

  (setf (cl-mpm::sim-gravity *sim*) -10d0)

  (format t "Starting test~%")
  (let ((start (get-internal-real-time))
        (output-dir (merge-pathnames (format nil "./data/output-~A-~a_~f_~d_~A/" *solver* *lstps* *refine* *mps* *agg*))))

    (cl-mpm/setup::set-mass-filter *sim* *density* :proportion 1d-9)

    (uiop:ensure-all-directories-exist (list output-dir))
    (cl-mpm/dynamic-relaxation::run-load-control
     *sim*
     :output-dir output-dir
     :load-steps *lstps*
     :substeps (round (* 25 (expt 1 *refine*)))
     :plotter (lambda (sim))
     :damping (sqrt 2d0)
     :save-vtk-dr nil
     :save-vtk-loadstep t
     :conv-steps 100
     :dt-scale 1d0
     :criteria 1d-9)

    (let* ((end (get-internal-real-time))
           (units internal-time-units-per-second)
           (dt (/ (- end start) units))
           (disp (compute-max-extent *sim*)))
      (with-open-file (stream  *data-file* :direction :output :if-exists :append)
        (format stream "~A,~D,~E,~D,~D,~A,~E,~E~%"
                *solver*
                *threads*
                (float *refine* 0e0)
                *lstps*
                *mps*
                *agg*
                (float dt 0e0)
                (float disp 0e0)
                ))
      )))

(defun compute-max-extent (sim)
  (cl-mpm::reduce-over-mps
   (cl-mpm:sim-mps sim)
   (lambda (mp)
     (cl-mpm/utils:varef (cl-mpm/fastmaths:fast-.+
                          (cl-mpm/particle::mp-domain-size mp)
                          (cl-mpm/particle::mp-position mp)) 0))
   #'max))

(defparameter *data-file* (merge-pathnames (format nil "data_~A.csv" *name*)))
(with-open-file (stream *data-file* :direction :output :if-exists nil)
    (format stream "solver,threads,refine,lstps,mps,agg,time,disp~%"))
(format t "Testing thread count: ~D ~%" *threads*)
(format t "Testing refine: ~E ~%" *refine*)
(test)
(cl-mpm/utils::kill-workers)
(sb-ext:gc :full t)
