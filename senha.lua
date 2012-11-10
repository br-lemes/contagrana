--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Suporte a senha e criptografia

if not grana then require("grana") end

require("md5")

grana.senha = {}
grana.senha.senha = iup.text{size="100", password="YES"}
grana.senha.ok = iup.button{title="OK", expand="HORIZONTAL"}
grana.senha.cancelar = iup.button{title="Cancelar", expand="HORIZONTAL"}
grana.senha.dialog = iup.dialog{title="Conta Grana", resize="NO", maxbox="NO", minbox="NO";
	iup.vbox{margin="10x10", gap="10";
		iup.hbox{margin="0x0";
			iup.frame{
				iup.hbox{margin="10x10";
					iup.label{title="Senha:", font=grana.font},
					grana.senha.senha
				}
			}
		},
		iup.hbox{margin="0x0"; grana.senha.ok, grana.senha.cancelar}
	}
}

function grana.senha.cancelar:action()
	grana.senha.dialog:hide()
end

function grana.senha.ok:action()
	grana.key = grana.senha.senha.value
	grana.senha.dialog:hide()
end

function grana.senha.dialog:k_any(k)
	if k == iup.K_ESC then
		grana.senha.cancelar:action()
	elseif k == iup.K_CR then
		grana.senha.ok:action()
	end
end

grana.senha.dialog:show()
iup.MainLoop()
