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
