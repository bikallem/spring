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
  let ohtml filepath =
    let fun_name = Fpath.v filepath |> Fpath.rem_ext |> Fpath.filename in
    let doc = Ohtml.parse_doc filepath in
    Out_channel.with_open_gen [ Open_wronly; Open_creat; Open_trunc; Open_text ]
      0o644 (fun_name ^ ".ml") (fun out ->
        let write_ln s = Out_channel.output_string out ("\n" ^ s) in
        Ohtml.gen_ocaml ~write_ln doc);
    Printf.printf "Generating view: %s" filepath
  in
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
  Cmd.group info [ ohtml_cmd ]

let main () = exit (Cmd.eval spring_cmd)
let () = main ()
