return vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
  textDocument = {
    completion = {
      completionItem = {
        snippetSupport = true,
        resolveSupport = {
          properties = {
            "documentation",
            "detail",
            "additionalTextEdits",
            "sortText",
            "filterText",
            "insertText",
            "textEdit",
            "insertTextFormat",
            "insertTextMode",
          },
        },
      },
    },
  },
})
