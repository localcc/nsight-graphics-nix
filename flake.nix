{
  description = "NVIDIA Nsight Graphics";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    patchelf.url = "github:localcc/patchelf/clobber-sections";
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
            version = "2026.1.0.26067";

            src = pkgs.fetchurl {
              url = "https://developer.nvidia.com/downloads/assets/tools/secure/nsight-graphics/2026_1_0/linux_x64/NVIDIA_Nsight_Graphics_2026.1.0.26067-linux_x64.run";
              hash = "sha256-6YhQKVrXxVWrsr29iTv4fbRIvz1RgPOhxLLq3uZ13vo=";
            };

            nativeBuildInputs = with pkgs; [
              (patchelf.packages.${system}.default)
              dpkg
              autoPatchelfHook
              cudaPackages.markForCudatoolkitRootHook
              makeBinaryWrapper
            ];

            autoPatchelfIgnoreMissingDeps = [
              "libQt6*"
            #   "*"
            ];
            patchelfFlags = [
              "--no-clobber-old-sections"
            ];
            appendRunpaths = [
              "/run/opengl-driver/lib"
              "${pkgs.libxi}/lib"
              "${pkgs.vulkan-loader}/lib"
              "${pkgs.wayland}/lib"
              "${pkgs.libxkbcommon}/lib"
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
              libxi
              cudaPackages.cuda_cudart
              vulkan-loader
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

              rm -rf $out/host/linux-desktop-nomad-x64/Plugins/WarpVizPlugin/Oracle
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
