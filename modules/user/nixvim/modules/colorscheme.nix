{ lib, ... }:

{
  programs.nixvim = {
    colorschemes = {
      rose-pine = {
        enable = true;
        settings = {
          style = "moon"; #  "main", "moon", "dawn" or raw lua code
          disableItalics = false;
          transparentFloat = true;
          transparentBackground = true;
        };
      };
    };
    extraConfigLua = lib.mkAfter ''
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function(args)
          if args.match ~= "rose-pine" then
            vim.schedule(function()
              vim.cmd.colorscheme("rose-pine")
            end)
          end
        end,
        desc = "Force rose-pine when other configs change the colorscheme",
      })
    '';
  };
}
