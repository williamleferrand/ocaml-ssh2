(* Lwt interface to SSH2 *)

open Lwt 

type conn = { 
  session : SSH2.session ; 
  fd : Lwt_unix.file_descr ; 
  mutable prompt : string ; 
}

(* Ok, this works fine when running in blocking mode *)

(* session_startup **************************************************************************)

(*
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
*)
(* Now we want pure non blocking mode with Lwt *)


(* We need a wait function that, well, works *)

let wait_read fd = 
  let t = Lwt_unix.wait_read fd in 
  let timeout = Lwt_timeout.create 1 (fun _ -> print_endline "> timeout!" ; Lwt.cancel t) in 
  Lwt_timeout.start timeout ;
  catch 
    (fun () -> t)
    (fun _ -> return ())
  
let session_startup session fd = 
  let rec keep_reading fd () =
    match SSH2.session_startup session (Lwt_unix.unix_file_descr fd) with 
        `Ok -> return () 
      | `Eagain -> Lwt_unix.wait_read fd >>= keep_reading fd in 
  Lwt_unix.wait_write fd >>= keep_reading fd

let session_disconnect conn msg = 
  let rec keep_reading conn () = 
    match SSH2.session_disconnect conn.session msg with 
      | `Ok -> return () 
      | `Eagain -> Lwt_unix.wait_read conn.fd >>= keep_reading conn in 
  Lwt_unix.wait_write conn.fd >>= keep_reading conn
  
let connect_nb host port = 
  let fd = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
  let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_of_string host, port) in 
  Lwt_unix.connect fd sockaddr 
  >>= fun _ -> 
  let session = SSH2.session_init () in
  SSH2.set_session_blocking session false ;
  session_startup session fd
  >>= fun () -> 
  return { session ; fd ; prompt = "$" }

let userauth_password username password conn =
  let rec keep_reading conn () =
    match SSH2.userauth_password conn.session username password with 
      | `Authenticated -> return true 
      | `Forbidden -> return false 
      | `Eagain -> Lwt_unix.wait_read conn.fd >>= keep_reading conn in 
  Lwt_unix.wait_write conn.fd >>= keep_reading conn  

let userauth_publickey_fromfile username publickey privatekey passphrase conn = 
  let rec keep_reading conn () = 
    match SSH2.userauth_publickey_fromfile conn.session username publickey privatekey passphrase with
      | `Authenticated -> return true
      | `Forbidden -> return false 
      | `Eagain -> Lwt_unix.wait_read conn.fd >>= keep_reading conn in 
  Lwt_unix.wait_write conn.fd >>= keep_reading conn

let channel_open_session conn = 
  let rec keep_reading conn () = 
    match SSH2.channel_open_session conn.session with
      | `Channel channel -> return channel 
      | `Eagain -> Lwt_unix.wait_read conn.fd >>= keep_reading conn in
  Lwt_unix.wait_write conn.fd >>= keep_reading conn

let channel_shell conn channel = 
  let rec keep_reading conn channel () = 
    match SSH2.channel_shell channel with 
        `Ready -> return () 
      | `Eagain -> Lwt_unix.wait_read conn.fd >>= keep_reading conn channel in
  Lwt_unix.wait_write conn.fd >>= keep_reading conn channel


let channel_request_pty conn channel = 
  let rec keep_reading conn channel () = 
    match SSH2.channel_request_pty channel with 
        `Ok -> return () 
      | `Eagain -> Lwt_unix.wait_read conn.fd >>= keep_reading conn channel in
  Lwt_unix.wait_write conn.fd >>= keep_reading conn channel
  
let channel_read conn channel = 
  let gbuf = Buffer.create 100 in   
  let rec keep_reading conn channel () = 
    let sbuflen = 8192 in 
    let sbuf = String.create sbuflen in 
    match SSH2.channel_read channel sbuf sbuflen with 
      | `Read 0 -> return (Buffer.contents gbuf)
      | `Read i -> Buffer.add_substring gbuf sbuf 0 sbuflen ; keep_reading conn channel ()
      | `Eagain -> if Buffer.length gbuf > 0 then return (Buffer.contents gbuf) else (Lwt_unix.wait_read conn.fd >>= keep_reading conn channel) in
  keep_reading conn channel ()

let check_prompt prompt s = 
  Printf.printf "Checking on string %s\n" s ; 
  if String.length s >= (String.length prompt) then 
    (try 
       ignore (Str.search_backward (Str.regexp_string prompt) s (String.length s - (String.length prompt))); true
     with Not_found -> false)
  else false
    
let channel_read_to_prompt conn channel = 
  let gbuf = Buffer.create 100 in   
  let rec keep_reading conn channel () = 
    let sbuflen = 8192 in 
    let sbuf = String.create sbuflen in 
    match SSH2.channel_read channel sbuf sbuflen with 
      | `Read 0 -> return (Buffer.contents gbuf)
      | `Read i -> Buffer.add_substring gbuf sbuf 0 i ; keep_reading conn channel ()
      | `Eagain -> let s = Buffer.contents gbuf in if check_prompt conn.prompt s then return s else (Lwt_unix.wait_read conn.fd >>= keep_reading conn channel) in
  keep_reading conn channel ()

let channel_write conn channel buf = 
  let rec keep_writing conn channel buf buflen () = 
    if buflen = 0 then return () 
    else 
      match SSH2.channel_write channel buf buflen with 
        | `Wrote 0 -> return () 
        | `Wrote i -> keep_writing conn channel (String.sub buf i (buflen - i)) (buflen - i) ()
        | `Eagain -> Lwt_unix.wait_write conn.fd >>= keep_writing conn channel buf buflen in 
  keep_writing conn channel buf (String.length buf) () 
    
