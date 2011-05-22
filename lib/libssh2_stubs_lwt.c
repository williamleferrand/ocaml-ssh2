/*
 * Cooperative bindings for libssh2
 */

// OCAML
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/signals.h>
#include <caml/config.h>
#include <caml/custom.h>
#include <caml/bigarray.h>

// LWT UNIX
#include "/opt/godi-3.12/lib/ocaml/site-lib/lwt/lwt_unix.h"

// LIBSSH2 

#include <libssh2.h>

/* Reminders from previous code */

#define Session_val(v) (*((LIBSSH2_SESSION **) Data_custom_val(v))) 

/* +-----------------------------------------------------------------+
   | JOB:                                                       |
   +-----------------------------------------------------------------+ */

struct job_session_startup {
  struct lwt_unix_job job;

  LIBSSH2_SESSION *session ; 
  int sock ; 

  int error_code;
};

#define Job_session_startup_val(v) *(struct job_session_startup**)Data_custom_val(v)

static void worker_session_startup(struct job_session_startup *job)
{
  int ret ; 
  ret = libssh2_session_startup(job->session, job->sock) ; 
  job->error_code = ret;
}

CAMLprim value lwt_ssh2_session_startup_job(value ocaml_session, value ocaml_socket)
{
  struct job_session_startup *job = lwt_unix_new(struct job_session_startup);

  job->job.worker = (lwt_unix_job_worker)worker_session_startup;
  
  job->session = Session_val (ocaml_session); 
  job->sock = Int_val (ocaml_socket) ;

  return lwt_unix_alloc_job(&(job->job));
}

CAMLprim value lwt_ssh2_session_startup_result(value val_job)
{
  struct job_session_startup *job = Job_session_startup_val(val_job);
  if (job->error_code) unix_error(job->error_code, "session_startup", Nothing);
  return Val_unit;
}

CAMLprim value lwt_ssh2_session_startup_free(value val_job)
{
  struct job_session_startup *job = Job_session_startup_val(val_job);
  lwt_unix_free_job(&job->job);
  return Val_unit;
}

