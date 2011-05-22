open Lwt 


let rec print_forever () = 
  Printf.printf "%f\n" (Unix.gettimeofday ()) ; 
  flush stdout ; 
  Lwt_unix.sleep 0.1 >>= print_forever 

let _ = 
  print_endline "test 4" ; 

  Lwt_main.run 
    (
      Lwt.ignore_result (print_forever ()); 
      SSH2_lwt.connect2 "188.165.201.126" 22 
      >>= fun conn -> 
      print_endline "connected" ;
      Lwt_unix.sleep 1.0 

      
    )
