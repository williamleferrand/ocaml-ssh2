let _ = 
  try 
    print_endline "libssh2 test"; 
    SSH2.init SSH2.INIT_NORMAL; 
    print_endline "everything is ok, .. exiting" 
  with e -> Printf.printf "Panic: %s\n" (Printexc.to_string e)

