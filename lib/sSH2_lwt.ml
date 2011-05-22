(* Lwt interface to SSH2 *)

open Lwt 

type conn = { 
  session : SSH2.session ; 
  fd : Lwt_unix.file_descr }



(* Connect *)

let connect host port = 
  let fd = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
  let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_of_string host, port) in 
  Lwt_unix.connect fd sockaddr 
  >>= fun _ -> 
  print_endline "calling init"; 
  let session = SSH2.session_init () in
  SSH2.session_startup session (Lwt_unix.unix_file_descr fd); (* Ok this operation is blocking *)
  return {
    session ; 
    fd 
  }


(* The stub for creating the job. *)
external session_startup_job : SSH2.session -> Unix.file_descr -> [ `ssh2_session_startup ] Lwt_unix.job = "lwt_ssh2_session_startup_job"

(* The stub for reading the result of the job. *)
external session_startup_result : [ `ssh2_session_startup ] Lwt_unix.job -> unit = "lwt_ssh2_session_startup_result"

(* The stub reading the result of the job. *)
external session_startup_free : [ `ssh2_session_startup ] Lwt_unix.job -> unit = "lwt_ssh2_session_startup_free"

(* And finally the ocaml function. *)
let session_startup session fd =
  Lwt_unix.execute_job (session_startup_job session fd) session_startup_result session_startup_free

let connect2 host port = 
  let fd = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
  let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_of_string host, port) in 
  Lwt_unix.connect fd sockaddr 
  >>= fun _ -> 
  print_endline "calling init"; 
  let session = SSH2.session_init () in
  session_startup session (Lwt_unix.unix_file_descr fd)
  >>= fun () -> 
  return {
    session ; 
    fd 
  }
