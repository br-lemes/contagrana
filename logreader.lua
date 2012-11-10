--
-- Copyright (c) 2012 Breno Ramalho Lemes
-- http://www.br-lemes.net
--
-- Leitor de log

if not grana then require("grana") end

grana.logreader = { }

grana.logreader.text   = iup.text{readonly="YES", expand="YES", multiline="YES", tabsize="1", font="COURIER_NORMAL_8"}
grana.logreader.dialog = iup.dialog{title="Log", size=grana.size; grana.logreader.text}

function grana.logreader.dialog:k_any(k)
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

function grana.logreader.make(alvo, titulo)
	if titulo then
		grana.logreader.dialog.title = "Log " .. titulo
	else
		grana.logreader.dialog.title = "Log"
	end
	local arquivo = io.open(grana.datadir .. alvo.arquivo .. ".log", "rb")
	local logstr = arquivo:read("*a")
	arquivo:close()
	if grana.key then
		local outstr = ""
		repeat
			local i, j = logstr:find("\nConta Grana Log\n")
			if i then
				logstr = logstr:sub(j + 1)
				local k = logstr:find("\nConta Grana Log\n")
				if k then k = k - 1 end
				outstr = outstr .. md5.decrypt(logstr:sub(1, k), grana.key)
			end
		until i == nil
		grana.logreader.text.value = outstr
	else
		grana.logreader.text.value = logstr
	end
	grana.logreader.dialog:popup(iup.CENTERPARENT, iup.CENTERPARENT)
end

grana.logreader.parentdialog = grana.parentdialog

function grana.parentdialog(dialog)
	grana.logreader.parentdialog(dialog)
	grana.logreader.dialog.parentdialog = dialog
end
