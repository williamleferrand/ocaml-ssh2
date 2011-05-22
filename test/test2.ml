let _ = 
  try 
    print_endline "libssh2 test - connection"; 

    let hostname = "188.165.201.126" in 
    let port = 22 in
    
    let username = Sys.argv.(1) in 
    let password = Sys.argv.(2) in 
    
   (* SSH2.init SSH2.INIT_NORMAL; *)
    
    let session = SSH2.session_init () in
    
    let sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in 
   
    Unix.connect sock (Unix.ADDR_INET (Unix.inet_addr_of_string hostname, port)) ; 
   
    print_endline "socket binded, calling session startup" ;
    SSH2.session_startup session sock ;
  
    print_endline "session is up" ;
    
    (match SSH2.userauth_password session username password with 
        true -> 
          print_endline "connection success"; 
          let channel = SSH2.channel_open_session session in 
          print_endline "channel is here" ; 
          SSH2.channel_exec channel "ls -l" ; 

          let buf = String.create 10000 in 
          let buflen = 10000 in 
          let len = SSH2.channel_read channel buf buflen in 
          Printf.printf "I read %d chars : %s\n" len (String.sub buf 0 len);
          let len = SSH2.channel_read channel buf buflen in 
          Printf.printf "I read %d chars : %s\n" len (String.sub buf 0 len);
          print_endline "new call"; 
          SSH2.channel_exec channel "ls -l" ; 
          let buf = String.create 10000 in 
          let buflen = 10000 in 
          let len = SSH2.channel_read channel buf buflen in 
          Printf.printf "I read %d chars : %s" len (String.sub buf 0 len);
          SSH2.channel_free channel 

      | false -> print_endline "connection failure (bad credentials)"); 

    SSH2.session_disconnect session "Normal shutdown" ; 
    SSH2.session_free session ;
    SSH2.eXit () ;
    print_endline "everything is ok, .. exiting" 
  with e -> Printf.printf "Panic: %s\n" (Printexc.to_string e)

