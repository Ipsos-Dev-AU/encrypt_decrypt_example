library(dplyr)
library(shiny)
library(data.table)
library(DT)
library(encryptr)
library(RODBC)
library(shinyjs)
library(shinyalert)
library(git2r)
# source(".Rprofile")
# print(Sys.getenv())

repo <- read.table(
  "Current_Branch.txt"
)
print(paste0("Repo: ",repo))

if (Sys.getenv("CONNECT_SERVER") != "https://au-rconnect.ipsos.com/") {
  print("You are in RWB")
  repo <- git2r::repository_head(git2r::repository("."))$name
  write.table(repo, "Current_Branch.txt", row.names = FALSE, col.names = FALSE)
  print(paste0("Re/Creating Current_Branch: ",repo))
}

repo <- read.table(
  "Current_Branch.txt"
)
print(paste0("Repo: ",repo))

unloadNamespace("git2r")

en <- function(x){
  x = as_tibble(x)
  x = encrypt(x, value)
  x = toString(x)
  return(x)
}

de <- function(x) {
  x = as_data_frame(x)
  print(x)
  x = decrypt(x, value)
  x = toString(x)
  return(x)
}

dbhandelstring <-
  paste0("driver=",Sys.getenv("driver"),
       ";server=",Sys.getenv("server"),
       ";database=",Sys.getenv("database"),
       ";trusted_connection=",Sys.getenv("trusted_connection"),
       ";uid=", Sys.getenv("uid"),
       ";pwd=", Sys.getenv("pwd")
  )

print(dbhandelstring)
       
dbhandle <-
  odbcDriverConnect(
    dbhandelstring
  )
  
get_data <- function(table, select="*", where="1 = 1") {
  qry_string <- paste("SELECT ", select, " FROM [",Sys.getenv("database"),"].[dbo].[", table , "] WHERE ", where, sep = "")
  print(qry_string)
  df <-
    return(RODBC::sqlQuery(
      dbhandle,
      qry_string,
      stringsAsFactors = FALSE,
      as.is = TRUE
    ))
  odbcCloseAll()
  return(df)
}

add_record <-
  function(FirstName,
           LastName,
           Bank) {
    qry_string <-
      paste(
        "INSERT INTO [dbo].[TestPowerApps] ([FirstName], [LastName], [Bank]) VALUES ('",
        FirstName,
        "', '",
        LastName,
        "', '",
        Bank,
        "')",
        sep = ""
      )
    df <-
      return(RODBC::sqlQuery(
        dbhandle,
        qry_string,
        stringsAsFactors = FALSE,
        as.is = TRUE
      ))
    odbcCloseAll()
    return(df, df2)
  }

ui <- fluidPage(
  useShinyjs(),
  br(),
  tags$h1("Encryption/Decryption with SQL back end - Testing Newer Feature"),
  tags$h6("This app demos how we could/should encrypt sensitive data at source and decrypt it only on user request an entry at a time."),
  hr(),
  tags$h6("Click on Add Record to add an entry to the table"),
  tags$h6("Click on a row to show the decrypted 'bank_col'"),
  tags$h6("The decrypted value is displayed only for a few seconds"),
  tags$h6("All data in bank_col at source is stored with encryption and is decrypted at destination for only the row selected"),
  tags$h6("All encription/decryption is done using a unique SSH key which is stored on the server where the app is hosted. In this apps case, the data is on PASQL01 server and the SSH key is on the Connect Server"),
  
  # Showing reactive table of all records
  DT::DTOutput("allrecords"),
  
  # Button to allow user to add a new record
  actionButton("add_record_bttn", "Add Record", class = "btn-primary"),
  hr(),
  
  # Form for the user to fill to save new or update existing
  uiOutput("name"),
  uiOutput("bank"),
  uiOutput("save"),
  tags$footer(
    HTML(paste0(
      "<!-- Footer -->
         <footer class='page-footer font-large indigo'>
         <!-- Copyright -->
         <div class='footer-copyright text-center py-3'>© 2022 Copyright:
         <a href='https://www.ipsos.com/en-au'> Ipsos All Rights Reserved</a>
         <b>", repo ,"
         </div>
         <!-- Copyright -->
         </footer>
         <!-- Footer -->"
    )
    )
  )
)

server <- function(input, output, session){
  # print(session)
  reactive_val <-
    reactiveValues(
      df_all_records = NULL
    )
  
  
  all_records <-
    get_data("TestPowerApps", select = "FirstName AS name_col, CAST(Bank AS varchar(8000)) AS bank_col")
  reactive_val$df_all_records <-
    all_records
  
  # Rendering table
  output$allrecords <-
    DT::renderDT(
      datatable(reactive_val$df_all_records, selection = 'single', rownames = FALSE)
    )
  
  # Showing form when add button is clicked
  observeEvent(input$add_record_bttn, {
    
    output$name <-
      renderUI(textInput("nameGiven", "Enter Name:"))
    output$bank <-
      renderUI(textInput("bankGiven", "Enter Bank:"))
    output$save <-
      renderUI(actionButton("save", "Save Record", class = "btn-success"))
  })
  
  # Writing back to SQL table
  observeEvent(input$save, {
    add_record(FirstName = input$nameGiven, LastName =  "NULL", Bank = en(input$bankGiven))
    all_records <-
      get_data("TestPowerApps", select = "FirstName AS name_col, CAST(Bank AS varchar(8000)) AS bank_col")
    reactive_val$df_all_records <-
      all_records
    shinyjs::reset("name")
    shinyjs::reset("bank")
  })
  
  # Showing form when and existing record is clicked
  observeEvent(input$allrecords_rows_selected, {
    print(input$allrecords_rows_selected)
    print(reactive_val$df_all_records[input$allrecords_rows_selected, "bank_col"])
    
    shinyalert(
      de(reactive_val$df_all_records[input$allrecords_rows_selected, "bank_col"]),
      type = "info",
      showConfirmButton = TRUE,
      showCancelButton = FALSE,
      closeOnEsc = TRUE,
      closeOnClickOutside = TRUE,
      inputId = "delApppmtConfirm",
      timer = 7000
    )
    shinyjs::reset("name")
    shinyjs::reset("bank")
  })
}

shinyApp(ui = ui, server = server)