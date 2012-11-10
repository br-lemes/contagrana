--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Caixa

require("grana")
require("senha")
require("notas")
require("troca")
require("reserva")
require("pagamento")

grana.carregar("caixa")
grana.carregar("reserva")

require("confere")

-- valor atual do pagamento
local valor = 0

-- limites de caixa
local limcaixa   = 4000
local limreserva = 5000
local limvalores = 2000

-- itens da interface
local comando   = iup.text{expand="HORIZONTAL", mask="[+/-]?(/d+/,?/d*|/,/d+)"}
local historico = iup.list{expand="YES"}
local total     = iup.label{title="Total R$ 0,00", expand="HORIZONTAL", alignment="ACENTER", font=grana.font}
local pagamento = iup.button{title="&Pagamento", expand="HORIZONTAL", font=grana.font}
local suprir    = iup.button{title="&Suprir",   expand="HORIZONTAL"}
local recolher  = iup.button{title="&Recolher", expand="HORIZONTAL"}
local reservar  = iup.button{title="Reser&var", expand="HORIZONTAL"}
local trocar    = iup.button{title="&Trocar",   expand="HORIZONTAL"}

-- troca de cor o botão reservar para fazer notar o saldo em caixa
function notificarsaldo()
	if caixa:total() > limcaixa or caixa:total() + reserva:total() > limreserva then
		reservar.fgcolor = "255 0 0"
	else
		if caixa[100] > 10 or
			caixa[50] > 20 or
			caixa[20] > 25 or
			caixa[10] > 25 or
			caixa[5]  > 20 or
			caixa[2]  > 25 then
			reservar.fgcolor = "0 0 255"
		else
			reservar.fgcolor = "0 0 0"
		end
	end
end

function pagamento:action()
	if valor == 0 then
		iup.Message("Pagamento", "Não há valor a pagar.")
	else
		caixa:log_string("\n-- Dados do Pagamento")
		for i = 1, historico.count do
			caixa:log_string("-- " .. historico[i])
		end
		caixa:log_string("-- " .. total.title)
		if grana.pagamento.make(valor, caixa) then
			historico.removeitem = "ALL"
			valor = 0
			total.title = "Total R$ 0,00"
		end
		caixa:log_write()
	end
	iup.SetFocus(comando)
	notificarsaldo()
end

function suprir:action()
	if reserva:total() ~= 0 then
		if grana.confirmar("Existe valor reservado, \ndeseja suprir da reserva?") == 1 then
			grana.suprimento.make(caixa, reserva)
		else
			grana.suprimento.make(caixa)
		end
	else
		grana.suprimento.make(caixa)
	end
	iup.SetFocus(comando)
	notificarsaldo()
end

function recolher:action()
	if reserva:total() ~= 0 then
		if grana.confirmar("Existe valor reservado, \ndeseja recolher da reserva?") == 1 then
			grana.recolhimento.make(reserva)
		else
			grana.recolhimento.make(caixa)
		end
	else
		grana.recolhimento.make(caixa)
	end
	iup.SetFocus(comando)
	notificarsaldo()
end

function reservar:action()
	grana.reserva.make(caixa, reserva)
	iup.SetFocus(comando)
	notificarsaldo()
end

function trocar:action()
	grana.troca.make(caixa)
	iup.SetFocus(comando)
	notificarsaldo()
end

local dlg = iup.dialog{title="Conta Grana - Caixa", size=grana.size;
	iup.vbox{margin="10x10", gap="10";
		iup.frame{
			iup.vbox{comando, historico, total, pagamento}
		},
		iup.hbox{margin="0x0"; suprir, recolher, reservar, confere.conferir, trocar}
	}
}

function dlg:close_cb()
	if grana.confirmar("Deseja realmente sair?") == 1 then
		self:hide()
	else
		historico.removeitem = "ALL"
		valor = 0
		total.title = "Total R$ 0,00"
		iup.SetFocus(comando)
		return iup.IGNORE
	end
end

function dlg:k_any(k)
	if k == iup.K_ESC then
		self:close_cb()
	elseif k == iup.K_l or k == iup.K_L then
		caixa:log_custom()
	elseif k == iup.K_s or k == iup.K_S then
		suprir:action()
	elseif k == iup.K_r or k == iup.K_R then
		recolher:action()
	elseif k == iup.K_v or k == iup.K_V then
		reservar:action()
	elseif k == iup.K_c or k == iup.K_C then
		confere.conferir:action()
		iup.SetFocus(comando)
	elseif k == iup.K_t or k == iup.K_T then
		trocar:action()
	elseif k == iup.K_n or k == iup.K_N then
		comando.value = grana.notas.make()
		iup.SetFocus(comando)
	elseif k == iup.K_p or k == iup.K_P or k == iup.K_F5 then
		pagamento:action()
	elseif k == iup.K_CR or #comando.value == 44 then
		if comando.value ~= "" then
			if #comando.value == 44 and comando.value:sub(1,1) == "8" then
				comando.value = comando.value:sub(5, 13) .. "." .. comando.value:sub(14, 15)
			end
			if math.abs(comando.value:gsub(",", ".")) <= limvalores then
				historico.insertitem1 = grana.real(comando.value:gsub(",", "."))
				historico.topitem = 1
				valor = valor + comando.value:gsub(",", ".")
				total.title = "Total " .. grana.real(valor)
				comando.value = ""
			end
		end
	elseif k == iup.K_F9 then
		grana.logreader.make(reserva, "Reserva")
		iup.SetFocus(comando)
	elseif k == iup.K_F12 then
		grana.logreader.make(caixa, "Caixa")
		iup.SetFocus(comando)
	elseif k == iup.K_F1 then
		iup.Message("Ajuda",
			"ESC\tSair\n" ..
			"L\tRegistrar log\n" ..
			"S\tSuprimento de numerário\n" ..
			"R\tRecolhimento de numerário\n" ..
			"V\tReserva de numerário\n" ..
			"C\tConferir saldo de numerário\n" ..
			"T\tEfetuar troca de numerário\n" ..
			"P ou F5\tEfetuar pagamento\n" ..
			"F9\tVer log da reserva\n" ..
			"F12\tVer log do caixa\n" ..
			"F1\tAjuda")
	end
end

notificarsaldo()
grana.parentdialog(dlg)
dlg:show()
iup.MainLoop()
