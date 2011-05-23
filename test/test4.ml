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
      SSH2_lwt.connect_nb "188.165.201.126" 22
      >>= fun conn ->
      print_endline "calling userauth" ;
      SSH2_lwt.userauth_password Sys.argv.(1) Sys.argv.(2) conn 
      >>= function 
        | false -> print_endline "forbidden" ; return ()
        | true -> print_endline "ok, authorized" ; 
          SSH2_lwt.channel_open_session conn 
          >>= fun channel -> 
          print_endline "we have the channel" ; 
          SSH2_lwt.channel_shell conn channel
          >>= fun _ -> 
          SSH2_lwt.channel_read conn channel  
          >>= fun s -> 
          print_endline s; 
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
          SSH2_lwt.session_disconnect conn "normal disconnect"
                    
    )
