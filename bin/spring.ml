open Cmdliner

let ohtml_file_cmd =
  let doc = "Generates Spring Ohtml views (.ml) from .ohtml files" in
  let man =
    [ `S Manpage.s_bugs
    ; `P "Bug reports to github.com/bikallem/spring/issues."
    ]
  in
  let info = Cmd.info "ohtml" ~version:"%%VERSION%%" ~doc ~man in
  let ohtml_file_arg =
    let doc = "directory wheren .ohtml files are located" in
    Arg.(required & pos 0 (some' string) None & info [] ~docv:"OHTML_DIR" ~doc)
  in
  let ohtml dir =
    let generate_file filepath =
      let fun_name = Filename.remove_extension filepath in
      let doc = Ohtml.parse_doc filepath in
      Out_channel.with_open_gen
        [ Open_wronly; Open_creat; Open_trunc; Open_text ]
        0o644 (fun_name ^ ".ml") (fun out ->
          let write_ln s = Out_channel.output_string out ("\n" ^ s) in
          Ohtml.gen_ocaml ~write_ln doc);
      Printf.printf "\nGenerating view: %s" filepath
    in
    Sys.readdir dir |> Array.to_list
    |> List.filter (fun x -> Filename.extension x = ".ohtml")
    |> List.iter (fun x -> generate_file x)
  in
  let ohtml_t = Term.(const ohtml $ ohtml_file_arg) in
  Cmd.v info ohtml_t

let spring_cmd =
  let doc = "Spring" in
  let man =
    [ `S Manpage.s_bugs
    ; `P "Bug reports to github.com/bikallem/spring/issues."
    ]
  in
  let info = Cmd.info "spring" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.group info [ ohtml_file_cmd ]

let main () = exit (Cmd.eval spring_cmd)
let () = main ()
