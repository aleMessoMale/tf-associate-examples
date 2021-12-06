variable "a_map" {
  type = map
  description = "a map to understand map"
  default = {
    name = "Alessandro"
    surname = "Casula"
  }
}

variable "a_list" {
  description = "a list to use"
  type = list(number)

  # non passerebbe il terraform validate o il terraform plan\apply
  #default = ["a",2,3,4]

  default = ["1",2,3,4]
}

variable "an_object" {
  type = object({
    name = string,
    surname = string,
    age = number
    fiscalCode = string
  })

  default = {
    name = "Alessandro",
    surname = "Casula",
    fiscalCode = "CSLLSN8XXXXX1G",
    # non passerebbe il validate
    # age = "xx"
    age = 40
  }
}

variable "a_tuple" {
  description = "a tuple"
  type = tuple([bool,number,string])
  default = [true,12,"Alex"]
}




output "a_map_surname" {
  value = var.a_map["surname"]
}

output "list_third_element" {
  value = var.a_list[2]
}

output "get_age_from_object" {
  value = var.an_object["age"]
}

output "second_tuple_element"{
  value = var.a_tuple[1]
}

output "whole_tuple" {
  value = var.a_tuple
}
