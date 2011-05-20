#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>

#include <libssh2.h>


/* The session data structure */


#define Session_val(v) (*((LIBSSH2_SESSION **) Data_custom_val(v))) 

void finalize_session (value v) {
  /* LIBSSH2_SESSION *session = Session_val(v) ; */
  // Insert here the cleaning code for session, cleaned while finalized (and uncomment in the context ..)
  return ;
}
 
static struct custom_operations session_op = {
  "libssh2.session",
  //(void *)finalize_session,
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

value alloc_session (LIBSSH2_SESSION *session) {
  value v = alloc_custom(&session_op, sizeof(LIBSSH2_SESSION *), 0, 1);
  Session_val (v) = session;
  return v;
}

#define Channel_val(v) (*((LIBSSH2_CHANNEL **) Data_custom_val(v))) 

void finalize_channel (value v) {
  /* LIBSSH2_CHANNEL *channel = Channel_val(v) ; */
  // Insert here the cleaning code for channel, cleaned while finalized (and uncomment in the context ..)
  return ;
}
 
static struct custom_operations channel_op = {
  "libssh2.channel",
  //(void *)finalize_channel,
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

value alloc_channel (LIBSSH2_CHANNEL *channel) {
  value v = alloc_custom(&channel_op, sizeof(LIBSSH2_CHANNEL *), 0, 1);
  Channel_val (v) = channel;
  return v;
}

/*
 * libssh2_init()
 */

value ocaml_libssh2_init (value ocaml_flag) {
  CAMLparam1 (ocaml_flag);
  int rc ;
  int flag ;

  flag = Int_val (ocaml_flag); 

  printf ("init flag is %d\n", flag) ;

  rc = libssh2_init (LIBSSH2_INIT_NO_CRYPTO);

  if (rc) caml_failwith("libssh2_init returned a non-zero rc") ;
  
  CAMLreturn (Val_unit);
}


/* 
 * libssh2_exit ()
 */

value ocaml_libssh2_exit (value unit) {
  CAMLparam1 (unit) ;
  
  libssh2_exit () ; 

  CAMLreturn (Val_unit); 
}

/*
 * libssh2_session_init ()
 */

value ocaml_libssh2_session_init (value unit) {
  CAMLparam1 (unit) ; 
  
  LIBSSH2_SESSION *session = libssh2_session_init ();
  
  if (!session)
    {
      caml_failwith("libssh2_session_init returned an invalid handle") ; 
    }
  
  CAMLreturn (alloc_session (session)); 
}

value ocaml_libssh2_session_free (value ocaml_session) {
  CAMLparam1 (ocaml_session) ; 
  LIBSSH2_SESSION *session = Session_val (ocaml_session); 
  libssh2_session_free (session) ;
  CAMLreturn (Val_unit) ;
}

// Ok now we deal with the business functions 

value ocaml_libssh2_base64_decode (value ocaml_session, value ocaml_input) {
  CAMLparam2 (ocaml_session, ocaml_input) ; 
  
  LIBSSH2_SESSION *session ; 
  
  const char *src; 
  unsigned int src_len = strlen (src) ; // Does not always work, but as the ocaml_input is supposed to be base64 encoded, the assumption holds

  char *data ; 
  unsigned int datalen ; 
  
  int ret ; 


  session = Session_val (ocaml_session) ;
  src = String_val (ocaml_input) ;

  ret = libssh2_base64_decode(session, &data, &datalen, src, src_len);

  if (ret) 
    {
      caml_failwith ("libssh2_base64_decode couldn't read the input string"); 
    }
  
  CAMLreturn (caml_copy_string (data)); 
}


/*
 * libssh_session_startup
 */

value ocaml_libssh2_session_startup (value ocaml_session, value ocaml_socket) {
  CAMLparam2 (ocaml_session, ocaml_socket); 

  LIBSSH2_SESSION *session ; 
  int sock ;
  int ret ; 

  session = Session_val (ocaml_session) ; 
  sock = Int_val (ocaml_socket) ;

  ret = libssh2_session_startup(session, sock) ; 

  if (ret) {
    caml_failwith ("ocaml_libssh2_session_startup can't connect to <sock>"); 
  }

  CAMLreturn (Val_unit); 
}


/*
 * libssh2_session_disconnect 
 */

value ocaml_libssh2_session_disconnect (value ocaml_session, value ocaml_description) {
  CAMLparam2 (ocaml_session, ocaml_description); 
  LIBSSH2_SESSION *session ; 
  int ret ;

  session = Session_val (ocaml_session) ; 

  ret = libssh2_session_disconnect (session, String_val (ocaml_description)); 
  
  if (ret) {
    caml_failwith ("ocaml_libssh2_session_disconnect returned non zero code") ; 
  }
  
  CAMLreturn (Val_unit) ;  
}


/*
 * libssh2_userauth_password
 */

value ocaml_libssh2_userauth_password (value ocaml_session, value username, value password) {
  CAMLparam3 (ocaml_session, username, password) ; 
  LIBSSH2_SESSION *session ; 
  int ret ; 
  session = Session_val (ocaml_session) ; 

  ret = libssh2_userauth_password (session, String_val (username), String_val (password)) ; 

  if (ret) {
    CAMLreturn (Val_bool (0)); 
  }
  
  CAMLreturn (Val_bool (1)) ;
}

/*
 * libssh2_channel_open_session
 */

value ocaml_libssh2_channel_open_session (value ocaml_session) {
  CAMLparam1 (ocaml_session) ;

  LIBSSH2_SESSION *session; 
  LIBSSH2_CHANNEL *channel;
  
  session = Session_val (ocaml_session) ; 
  
  if (!(channel = libssh2_channel_open_session(session))) {
    caml_failwith ("ocaml_libssh2_channel_open_session coundn't open session"); 
  }

  CAMLreturn (alloc_channel (channel)); 
}


/*
 * libssh2_channel_free
 */ 

value ocaml_libssh2_channel_free (value ocaml_channel) {
  CAMLparam1 (ocaml_channel) ;

  LIBSSH2_CHANNEL *channel; 
  channel = Channel_val (ocaml_channel) ;
  int ret ;
  
  ret = libssh2_channel_free (channel) ;
  
  if (ret) {
    caml_failwith ("ocaml_libssh2_channel_free returned a non zero value"); 
  }
  
  CAMLreturn (Val_unit); 
}

/*
 * libssh2_channel_setenv
 */

value ocaml_libssh2_channel_setenv (value ocaml_channel, value ocaml_varname, value ocaml_value) {
  CAMLparam3 (ocaml_channel, ocaml_varname, ocaml_value) ; 
  LIBSSH2_CHANNEL *channel ; 
  int ret ;
 
  channel = Channel_val (ocaml_channel) ;
  ret = libssh2_channel_setenv (channel, String_val (ocaml_varname), String_val (ocaml_value)) ;

  if (ret) {
    caml_failwith ("libssh2_channel_setenv returned a nonzero code, the changed are probably not applied"); 
  }
 
  CAMLreturn (Val_unit);  
}


/*
 * libssh2_channel_request_pty 
 */

// Ok here we hide the "vanilla" termcap, as you don't want anything else do you ? :) 

value ocaml_libssh2_channel_request_pty (value ocaml_channel) {
  CAMLparam1 (ocaml_channel); 

  LIBSSH2_CHANNEL *channel ; 
  int ret ;
 
  channel = Channel_val (ocaml_channel) ;
  ret = libssh2_channel_request_pty (channel, "vanilla"); 

  if (ret) {
    caml_failwith ("libssh2_channel_request_pty returned a nonzero code, the changed are probably not applied"); 
  }
  
  CAMLreturn (Val_unit); 
}


/*
 * libssh2_channel_exec 
 */

value ocaml_libssh2_channel_exec (value ocaml_channel, value ocaml_command) {
  CAMLparam2 (ocaml_channel, ocaml_command); 
  LIBSSH2_CHANNEL *channel ; 
  int ret ;
 
  channel = Channel_val (ocaml_channel) ;
  ret = libssh2_channel_exec (channel, String_val (ocaml_command)); 

  if (ret) {
    caml_failwith ("libssh2_channel_exec returned a nonzero code"); 
  }
  
  CAMLreturn (Val_unit);
  

}

/*
 * libssh2_channel_read 
 */ 

value ocaml_libssh2_channel_read (value ocaml_channel, value ocaml_buf, value ocaml_buflen) {
  CAMLparam3 (ocaml_channel, ocaml_buf, ocaml_buflen);
  
  LIBSSH2_CHANNEL *channel ; 
  int ret ;
  
  channel = Channel_val (ocaml_channel) ;
  ret = libssh2_channel_read (channel, String_val (ocaml_buf), Int_val (ocaml_buflen)) ;
  
  CAMLreturn (Val_int (ret)) ;
}
