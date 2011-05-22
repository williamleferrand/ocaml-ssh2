(* Lwt interface to SSH2 *)

open Lwt 

type conn = { 
  session : SSH2.session ; 
  fd : Lwt_unix.file_descr }

(* Ok, this works fine when running in blocking mode *)

(* session_startup **************************************************************************)

external session_startup_job : SSH2.session -> Unix.file_descr -> [ `ssh2_session_startup ] Lwt_unix.job = "lwt_ssh2_session_startup_job"
external session_startup_result : [ `ssh2_session_startup ] Lwt_unix.job -> unit = "lwt_ssh2_session_startup_result"
external session_startup_free : [ `ssh2_session_startup ] Lwt_unix.job -> unit = "lwt_ssh2_session_startup_free"

let session_startup session fd = 
  Lwt_unix.execute_job (session_startup_job session fd) session_startup_result session_startup_free

(* Utility function *************************************************************************)

let connect host port = 
  let fd = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
  let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_of_string host, port) in 
  Lwt_unix.connect fd sockaddr 
  >>= fun _ -> 
  print_endline "calling init"; 
  let session = SSH2.session_init () in
  SSH2.set_session_blocking session true ;
  session_startup session (Lwt_unix.unix_file_descr fd)
  >>= fun () -> 
  return { session ; fd }

(* Now we want pure non blocking mode with Lwt *)

let session_startup session fd = 
  let rec keep_reading fd () =
    match SSH2.session_startup session (Lwt_unix.unix_file_descr fd) with 
        true -> return () 
      | false -> Lwt_unix.wait_read fd >>= keep_reading fd in 
  Lwt_unix.wait_write fd >>= keep_reading fd

let userauth_password username password conn =
  print_endline "userauth" ;
  let rec keep_reading conn () =
    match SSH2.userauth_password conn.session username password with 
      | SSH2.Authenticated -> return true 
      | SSH2.Forbidden -> return false 
      | SSH2.EAGAIN -> Lwt_unix.wait_read conn.fd >>= keep_reading conn in 
  Lwt_unix.wait_write conn.fd >>= keep_reading conn  

let connect_nb host port = 
  let fd = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
  let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_of_string host, port) in 
  Lwt_unix.connect fd sockaddr 
  >>= fun _ -> 
  print_endline "calling init"; 
  let session = SSH2.session_init () in
  SSH2.set_session_blocking session false ;
  session_startup session fd
  >>= fun () -> 
  return { session ; fd }
