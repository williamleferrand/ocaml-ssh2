open Lwt 

open SSH2_lwt

let rec print_forever () = 
  Printf.printf "%f\n" (Unix.gettimeofday ()) ; 
  flush stdout ; 
  Lwt_unix.sleep 0.1 >>= print_forever 

let _ = 
  print_endline "test 4" ; 

  Lwt_main.run 
    (

      Lwt.ignore_result (print_forever ()); 

      let host = "50.16.86.62" in
      SSH2_lwt.connect_nb host 22
      >>= fun conn ->
      print_endline "calling userauth" ;
      SSH2_lwt.userauth_publickey_fromfile Sys.argv.(1) Sys.argv.(2) Sys.argv.(3) Sys.argv.(4) conn
      >>= function 
        | false -> print_endline "forbidden" ; return ()
        | true -> print_endline "ok, authorized" ; 
          SSH2_lwt.channel_open_session conn 
          >>= fun channel -> 
          print_endline "we have the channel" ; 
          
          SSH2_lwt.channel_request_pty conn channel 
          >>= fun _ -> print_endline "we have a pty" ;
          SSH2_lwt.channel_shell conn channel
          >>= fun _ ->
          (* print_endline "reading .." ; 
          SSH2_lwt.channel_read conn channel  
          >>= fun s -> 
          print_endline s; *) 
          
          SSH2_lwt.channel_write conn channel "ls -l\n" 
          >>= fun _ ->
          print_endline "ok"; 
          SSH2_lwt.channel_read conn channel  
          >>= fun s -> 
          print_endline s; 
          SSH2_lwt.channel_write conn channel "cd /tmp\n" 
          >>= fun _ ->
          
          SSH2_lwt.channel_write conn channel "ls -l\n" 
          >>= fun _ ->
          print_endline "ok"; 
          SSH2_lwt.channel_read conn channel  
          >>= fun s -> 
          print_endline s; 
          Lwt_unix.sleep 10000.0 
          >>= fun _ -> 
          SSH2_lwt.session_disconnect conn "normal disconnect"
                    
    )
