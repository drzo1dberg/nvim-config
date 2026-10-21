-- Speichert beim Verlassen des Insert-Mode, nur fuer echte Dateien mit Aenderungen.
vim.api.nvim_create_autocmd("InsertLeave", {
	group = vim.api.nvim_create_augroup("custom-autosave", { clear = true }),
	callback = function(event)
		local bo = vim.bo[event.buf]
		if bo.buftype == "" and bo.modifiable and not bo.readonly and vim.api.nvim_buf_get_name(event.buf) ~= "" then
			vim.cmd("silent! update")
		end
	end,
})
