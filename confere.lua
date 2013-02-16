--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Confere saldo do caixa

if not grana then require("grana") end
if not caixa then grana.carregar("caixa") end
if not reserva then grana.carregar("reserva") end

confere = { }

confere.conferir = iup.button{title="&Conferir", expand="HORIZONTAL"}
confere.notas    = iup.label{expand="HORIZONTAL", alignment="ACENTER", font=grana.font}
confere.moedas   = iup.label{expand="HORIZONTAL", alignment="ACENTER", font=grana.font}
confere.total    = iup.label{expand="HORIZONTAL", alignment="ACENTER", font=grana.font}
confere.dialog   = iup.dialog{title="Conferência", rastersize=grana.rastersize;
	iup.vbox{margin="10x10", gap="10"; caixa.box, iup.fill{}, reserva.box, iup.fill{},
		iup.hbox{homogeneous="YES", margin="0x0";
			iup.frame{confere.notas},
			iup.frame{confere.moedas},
			iup.frame{confere.total}
		}
	}
}

function confere.dialog:k_any(k)
	if k == iup.K_ESC then
		self:hide()
	elseif k == iup.K_l or k == iup.K_L then
		caixa:log_custom()
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair\n" ..
			"L\tRegistrar log\n" ..
			"F1\tAjuda")
	end
end

function confere.conferir:action()
	confere.notas.title  = "Notas "  .. grana.real(caixa:notas() + reserva:notas())
	confere.moedas.title = "Moedas " .. grana.real(caixa.moedas + reserva.moedas)
	confere.total.title  = "Total "  .. grana.real(caixa:total() + reserva:total())
	caixa:box_update{[2]=25, [5]=20, [10]=25, [20]=25, [50]=20, [100]=10}
	confere.dialog:popup(iup.CENTERPARENT, iup.CENTERPARENT)
end

confere.parentdialog = grana.parentdialog

function grana.parentdialog(dialog)
	confere.parentdialog(dialog)
	confere.dialog.parentdialog = dialog
end
