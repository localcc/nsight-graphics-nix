{
  description = "NVIDIA Nsight Graphics";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    patchelf.url = "git+file:///home/kate/dev/patchelf";
  };

  outputs =
    { nixpkgs, patchelf, ... }:
    let
      system = "x86_64-linux";
    in
    {
      packages.${system} =
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "nsight-graphics";
            version = "2025.5.0.25335";

            src = pkgs.fetchurl {
              url = "https://developer.nvidia.com/downloads/assets/tools/secure/nsight-graphics/2025_5_0/linux/NVIDIA_Nsight_Graphics_2025.5.0.25335.run";
              hash = "sha256-UMEKzxG8fQhHUC8iZP10JISzMrn2mgjXoJaY2O55AbI=";
            };

            nativeBuildInputs = with pkgs; [
              (patchelf.packages.${system}.default)
              dpkg
              autoPatchelfHook
              cudaPackages.markForCudatoolkitRootHook
              makeBinaryWrapper
            ];

            autoPatchelfIgnoreMissingDeps = [
              "*"
            ];
            patchelfFlags = [
              "--no-clobber-old-sections"
            ];
            appendRunpaths = [
              "/run/opengl-driver/lib"
            ];

            buildInputs = with pkgs; [
              libxkbcommon
              libGL
              wayland
              xorg.libxcb
              fontconfig
              libxcb-util
              libxcb-cursor
              libxcb-keysyms
              libxcb-wm
              libpng
              dbus
              libgcc
              libuuid
              glib
              cudaPackages.cuda_cudart
            ];

            dontConfigure = true;
            dontBuild = true;
            dontStrip = true;

            unpackCmd = ''
              mkdir source-run
              cp $curSrc source-run/source.run
            '';

            installPhase = ''
              chmod +x source.run 
              ./source.run --accept --target source --noexec -- -noprompt

              mkdir -p $out/bin
              
              cp -R source/pkg/* $out

              find $out -name "*.so*" -type f -exec chmod -x {} +

              patchShebangs $out/host/linux-desktop-nomad-x64/install-desktop.sh
              $out/host/linux-desktop-nomad-x64/install-desktop.sh linux "$out" "$out/bin"
              cp -R $out/usr/* $out/
              rm -rf $out/usr
              

              runHook preInstall

              runHook postInstall

              makeWrapper $out/host/linux-desktop-nomad-x64/ngfx-ui.bin $out/bin/ngfx-ui \
                --prefix QT_PLUGIN_PATH : "$out/host/linux-desktop-nomad-x64/Plugins"
            '';
          };
        };
    };
}
