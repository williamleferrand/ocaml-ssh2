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
      >>= SSH2_lwt.userauth_password Sys.argv.(1) Sys.argv.(2) 
      >>= function 
        | false -> print_endline "forbidden" ; return ()
        | true -> print_endline "ok, authorized" ; return ()
              
    )
