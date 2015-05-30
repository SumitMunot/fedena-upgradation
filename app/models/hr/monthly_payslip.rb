# == Schema Information
#
# Table name: monthly_payslips
#
#  id                  :integer          not null, primary key
#  salary_date         :date
#  employee_id         :integer
#  payroll_category_id :integer
#  amount              :string(255)
#  is_approved         :boolean          default(FALSE), not null
#  approver_id         :integer
#  is_rejected         :boolean          default(FALSE), not null
#  rejector_id         :integer
#  reason              :string(255)
#  remark              :string(255)
#

#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class MonthlyPayslip < ActiveRecord::Base

  validates_presence_of :salary_date

  belongs_to :payroll_category
  belongs_to :employee
  belongs_to :approver ,:class_name => 'User'
  belongs_to :rejector ,:class_name => 'User'

  def approve(user_id,remark)
    self.is_approved = true
    self.approver_id = user_id
    self.remark = remark
    self.save
  end

  def reject(user_id, reason)
    self.is_rejected = true
    self.rejector_id = user_id
    self.reason = reason
    self.save
  end

  def self.find_and_filter_by_department(salary_date,dept_id)
    payslips = ""
    individual_payslip_category = ""
    unless dept_id =="All"
      active_employees_in_dept = Employee.select(:id).where(:employee_department_id => dept_id)
      archived_employees_in_dept = ArchivedEmployee.select(:former_id).where(employee_department_id: dept_id)
      all_employees_in_dept = active_employees_in_dept.collect(&:id) + archived_employees_in_dept.collect{|a| a.former_id.to_i}
      payslips = self.where(salary_date: salary_date.to_date, employee_id: all_employees_in_dept).order("payroll_category_id ASC").includes(:payroll_category)
      individual_payslip_category = IndividualPayslipCategory.where(salary_date: salary_date.to_date, employee_id: all_employees_in_dept).order("id ASC")
    else
      payslips = self.where(salary_date: salary_date.to_date).order("payroll_category_id ASC").includes(:payroll_category)
      individual_payslip_category = IndividualPayslipCategory.where(salary_date: salary_date.to_date).order("id ASC")
    end
    grouped_monthly_payslips = payslips.group_by(&:employee_id) unless payslips.blank?
    grouped_individual_payslip_categories = individual_payslip_category.group_by(&:employee_id) unless individual_payslip_category.blank?
    return_hash = { monthly_payslips: grouped_monthly_payslips, individual_payslip_category: grouped_individual_payslip_categories }
    return_hash
  end

  def active_or_archived_employee
    employee = Employee.where(id: self.employee_id).first
    if employee.blank?
      return  ArchivedEmployee.where(former_id: self.employee_id).first
    else
      return employee
    end
  end


  def status_as_text
    if is_approved == true
      status = I18n.t('approved')
    elsif is_rejected == true
      status = I18n.t('rejected')
    else
      status = I18n.t('pending')
    end
    return status
  end


  def self.total_employees_salary(start_date,end_date,dept_id="")
    total_monthly_payslips  = ""
    unless dept_id.blank?
      active_employees_in_dept = Employee.select("id").where(employee_department_id: dept_id)
      archived_employees_in_dept = ArchivedEmployee.select("former_id").where(employee_department_id: dept_id)
      all_employees_in_dept = active_employees_in_dept.collect(&:id) + archived_employees_in_dept.collect{|a| a.former_id.to_i}
      total_monthly_payslips = self.select("employee_id,amount,payroll_category_id,salary_date").order('salary_date desc').where("salary_date >= ? and salary_date <= ? and is_approved = 1 and employee_id IN (?)",start_date.to_date,end_date.to_date,all_employees_in_dept).includes(:payroll_category)
    else
      total_monthly_payslips = self.select("employee_id,amount,payroll_category_id,salary_date").order('salary_date desc').where("salary_date >= ? and salary_date <= ? and is_approved = 1", start_date.to_date, end_date.to_date).includes(:payroll_category)
    end

    employee_ids = []
    employee_ids = total_monthly_payslips.collect(&:employee_id) unless total_monthly_payslips.blank?
    unless employee_ids.blank?
      employee_ids.uniq!
      total_individual_payslips = IndividualPayslipCategory.where("salary_date >= '#{start_date.to_date}' and salary_date <= '#{end_date.to_date}' AND employee_id IN (#{employee_ids.join(",")})").order("id ASC")
    end
    total_salary = 0
    unless total_monthly_payslips.blank?
      total_monthly_payslips.each do |payslip|
        total_salary += payslip.amount.to_f if payslip.payroll_category.is_deduction==false
        total_salary -= payslip.amount.to_f if payslip.payroll_category.is_deduction==true
      end
    end
    unless total_individual_payslips.blank?
      total_individual_payslips.each do |payslip|
        total_salary += payslip.amount.to_f if payslip.is_deduction==false
        total_salary -= payslip.amount.to_f if payslip.is_deduction==true
      end
    end
    { total_salary: total_salary, monthly_payslips: total_monthly_payslips, individual_categories: total_individual_payslips}
  end


end
