open Cmdliner

let ohtml_cmd =
  let doc = "Generate Spring view from .ohtml template file" in
  let man =
    [ `S Manpage.s_bugs
    ; `P "Email bug reports to github.com/bikallem/spring/issues."
    ]
  in
  let info = Cmd.info "ohtml" ~version:"%%VERSION%%" ~doc ~man in
  let ohtml_file_arg =
    let doc = ".ohtml filename" in
    Arg.(required & pos 0 (some' string) None & info [] ~docv:"OHTML_FILE" ~doc)
  in
  let ohtml filepath = Printf.printf "Generating view: %s" filepath in
  let ohtml_t = Term.(const ohtml $ ohtml_file_arg) in
  Cmd.v info ohtml_t

let spring_cmd =
  let doc = "Spring" in
  let man =
    [ `S Manpage.s_bugs
    ; `P "Email bug reports to github.com/bikallem/spring/issues."
    ]
  in
  let info = Cmd.info "spring" ~version:"%%VERSION%%" ~doc ~man in
  let spring () = print_string "spring says hello" in
  let spring_t = Term.(const spring $ const ()) in
  Cmd.group ~default:spring_t info [ ohtml_cmd ]

let main () = exit (Cmd.eval spring_cmd)
let () = main ()
