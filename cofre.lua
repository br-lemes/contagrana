--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Cofre

require("grana")
require("senha")

grana.carregar("cofre")

local suprir   = iup.button{title = "&Suprir",   expand="HORIZONTAL", action=function() grana.suprimento.make(cofre) end}
local recolher = iup.button{title = "&Recolher", expand="HORIZONTAL", action=function() grana.recolhimento.make(cofre) end}

local dlg = iup.dialog{title="Conta Grana - Cofre", size=grana.size;
	iup.vbox{margin="10x10", gap="10";
		iup.hbox{margin="0x0", suprir, recolher},
		cofre.box }
}

function dlg:close_cb()
	if grana.confirmar("Deseja realmente sair?") == 1 then
		self:hide()
	else
		return iup.IGNORE
	end
end

function dlg:k_any(k)
	if k == iup.K_ESC then
		self:close_cb()
	elseif k == iup.K_l or k == iup.K_L then
		cofre:log_custom()
	elseif k == iup.K_s or k == iup.K_S then
		suprir:action()
	elseif k == iup.K_r or k == iup.K_R then
		recolher:action()
	elseif k == iup.K_F12 then
		grana.logreader.make(cofre, "Cofre")
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair\n" ..
			"L\tRegistrar log\n" ..
			"S\tSuprimento de numerário\n" ..
			"R\tRecolhimento de numerário\n" ..
			"F12\tVer log do cofre\n" ..
			"F1\tAjuda")
	end
end
grana.parentdialog(dlg)
dlg:show()
iup.MainLoop()
