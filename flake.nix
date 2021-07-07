{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/21.05;


  outputs = { self, nixpkgs, }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

    in
      {
        devShell = forAllSystems (system: 

          let
            pkgs = nixpkgs.legacyPackages.${system};
            lua = pkgs.lua5_3.withPackages (ps: with ps; [
              ps.busted
              ps.ldoc
            ]);
          in
            pkgs.mkShell {
              buildInputs = 
              [
                lua
              ];
            }
        );
      };
}
