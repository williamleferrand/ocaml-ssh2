let _ = 
  try 
    print_endline "libssh2 test"; 
    SSH2.init SSH2.INIT_NORMAL;
    let session = SSH2.session_init () in
    let s = SSH2.base64_decode session "Zm5vcmQ=" in
    Printf.printf "Decoded string is %s\n" s ; 
    SSH2.session_free session ;
    SSH2.eXit () ;
    print_endline "everything is ok, .. exiting" 
  with e -> Printf.printf "Panic: %s\n" (Printexc.to_string e)

