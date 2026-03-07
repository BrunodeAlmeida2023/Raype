class HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :set_outdoor, only: [:find_outdoor, :find_date, :choose_art, :finalize_budget]

  def index
    @user = current_user
    @outdoor = current_user.outdoor

    # 🔒 Se o outdoor tem datas salvas que agora estão bloqueadas, limpa as datas automaticamente
    if @outdoor && outdoor_dates_blocked?(@outdoor)
      @outdoor.update(selected_start_date: nil, selected_end_date: nil)
      flash.now[:alert] = "As datas selecionadas não estão mais disponíveis. Por favor, selecione novas datas."
    end
  end

  def show
    redirect_to root_path
  end

  def find_outdoor
    # Bloqueia se tem rent pendente ou pago
    if current_user.rents.where(status: ['pending', 'paid']).exists?
      rent = current_user.rents.where(status: ['pending', 'paid']).first
      if rent.status == 'paid'
        redirect_to root_path, alert: "Você já possui um pedido pago. Não é possível alterar as informações. Entre em contato via WhatsApp se precisar."
      else
        redirect_to order_status_path(rent.id), alert: "Você possui um pedido pendente. Cancele-o antes de fazer alterações."
      end
      return
    end

    # @outdoor já está setado pelo before_action
  end

  def find_date
    # Bloqueia se tem rent pendente ou pago
    if current_user.rents.where(status: ['pending', 'paid']).exists?
      rent = current_user.rents.where(status: ['pending', 'paid']).first
      if rent.status == 'paid'
        redirect_to root_path, alert: "Você já possui um pedido pago. Não é possível alterar as informações. Entre em contato via WhatsApp se precisar."
      else
        redirect_to order_status_path(rent.id), alert: "Você possui um pedido pendente. Cancele-o antes de fazer alterações."
      end
      return
    end

    # 🔒 Se a data salva agora está bloqueada, limpa para forçar nova seleção
    if outdoor_dates_blocked?(@outdoor)
      @outdoor.update(selected_start_date: nil, selected_end_date: nil)
      flash.now[:alert] = "As datas selecionadas não estão mais disponíveis. Por favor, selecione novas datas."
    end

    # @outdoor já está setado pelo before_action
  end

  def choose_art
    # Bloqueia se tem rent pendente ou pago
    if current_user.rents.where(status: ['pending', 'paid']).exists?
      rent = current_user.rents.where(status: ['pending', 'paid']).first
      if rent.status == 'paid'
        redirect_to root_path, alert: "Você já possui um pedido pago. Não é possível alterar as informações. Entre em contato via WhatsApp se precisar."
      else
        redirect_to order_status_path(rent.id), alert: "Você possui um pedido pendente. Cancele-o antes de fazer alterações."
      end
      return
    end

    # @outdoor já está setado pelo before_action
  end

  def finalize_budget
    # Verifica se o usuário já possui um orçamento pago
    paid_rent = current_user.rents.where(status: 'paid').first

    if paid_rent.present?
      whatsapp_message = "Olá! Acabei de realizar o pagamento do meu outdoor (Pedido ##{paid_rent.id}). Gostaria de enviar as informações para impressão."
      whatsapp_url = "https://wa.me/5546999776924?text=#{URI.encode_www_form_component(whatsapp_message)}"
      redirect_to whatsapp_url, allow_other_host: true, alert: "Você já possui um pedido pago. Entre em contato via WhatsApp para enviar suas informações."
      return
    end

    # Verifica se o usuário já possui um orçamento pendente
    existing_rent = current_user.rents.where(status: 'pending').first

    if existing_rent.present?
      redirect_to order_status_path(existing_rent.id), alert: "Você já possui um orçamento pendente. Finalize ou cancele-o antes de criar um novo."
      return
    end

    # 🔒 VALIDAÇÃO: Verifica se as datas salvas agora estão bloqueadas
    if outdoor_dates_blocked?(@outdoor)
      @outdoor.update(selected_start_date: nil, selected_quantity_month: nil)
      redirect_to find_date_home_path, alert: "As datas selecionadas não estão mais disponíveis. Por favor, selecione novas datas."
      return
    end

    # @outdoor já está setado pelo before_action
  end

  def post_find_outdoor
    @outdoor = current_user.outdoor || current_user.build_outdoor


    if @outdoor.update(outdoor_params)
      flash[:notice] = "Outdoor salvo com sucesso!"
      redirect_to root_path
    else
      flash[:alert] = "Erro ao salvar outdoor: #{@outdoor.errors.full_messages.join(', ')}"
      redirect_to find_outdoor_home_path
    end
  end

  def post_find_date
    @outdoor = current_user.outdoor || current_user.build_outdoor

    start_date = params[:selected_start_date]
    end_date = params[:selected_end_date]

    # Validação no backend: ambas as datas devem estar presentes
    if start_date.blank? || end_date.blank?
      flash[:alert] = "Por favor, selecione ambas as datas (inicial e final)."
      redirect_to find_date_home_path
      return
    end

    begin
      start_date_parsed = Date.parse(start_date)
      end_date_parsed = Date.parse(end_date)
    rescue ArgumentError
      flash[:alert] = "Datas inválidas. Por favor, verifique os valores informados."
      redirect_to find_date_home_path
      return
    end

    # Validação: data final deve ser posterior à inicial
    if end_date_parsed <= start_date_parsed
      flash[:alert] = "A data final deve ser posterior à data inicial."
      redirect_to find_date_home_path
      return
    end

    # Validação: deve ter o mesmo dia do mês
    if start_date_parsed.day != end_date_parsed.day
      flash[:alert] = "A data final deve ter o mesmo dia do mês que a data inicial (dia #{start_date_parsed.day})."
      redirect_to find_date_home_path
      return
    end

    # Validação: calcula diferença de meses
    months_diff = (end_date_parsed.year - start_date_parsed.year) * 12 +
                  (end_date_parsed.month - start_date_parsed.month)

    # Validação: deve ser pelo menos 1 mês
    if months_diff < 1
      flash[:alert] = "O período deve ser de no mínimo 1 mês."
      redirect_to find_date_home_path
      return
    end

    # 🔒 VALIDAÇÃO: Verifica se o período está bloqueado (por outdoor individual)
    if OutdoorBlockedDate.blocked_between?(@outdoor.id, start_date_parsed, end_date_parsed)
      flash[:alert] = "Este período não está disponível. Há datas bloqueadas no intervalo selecionado. Por favor, escolha outras datas."
      redirect_to find_date_home_path
      return
    end

    # 🔒 VALIDAÇÃO: Verifica se a LOCALIZAÇÃO está bloqueada pelo admin (clientes presenciais)
    if @outdoor.outdoor_location.present? &&
       LocationBlockedDate.location_blocked_for_period?(@outdoor.outdoor_location, start_date_parsed, end_date_parsed)
      next_available = LocationBlockedDate.minimum_start_date_for_location(@outdoor.outdoor_location)
      flash[:alert] = "Este período não está disponível para a localização selecionada. " \
                      "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}. Por favor, escolha outra data."
      redirect_to find_date_home_path
      return
    end

    if @outdoor.update(selected_start_date: start_date_parsed, selected_end_date: end_date_parsed)
      flash[:notice] = "Data salva com sucesso!"
      redirect_to root_path
    else
      flash[:alert] = "Erro ao salvar data: #{@outdoor.errors.full_messages.join(', ')}"
      redirect_to find_date_home_path
    end
  end

  def post_choose_art
    @outdoor = current_user.outdoor || current_user.build_outdoor

    # Log dos parâmetros recebidos
    Rails.logger.info "🎨 post_choose_art - Params recebidos:"
    Rails.logger.info "   has_own_art: #{params[:has_own_art]}"
    Rails.logger.info "   selected_faces: #{params[:selected_faces]}"

    # 1. Valida e salva se o usuário tem arte própria
    has_own_art = params[:has_own_art]
    if has_own_art.blank?
      flash[:alert] = "Por favor, selecione se você tem artes prontas ou não."
      redirect_to choose_art_home_path
      return
    end

    @outdoor.has_own_art = (has_own_art == 'true')

    # 2. Valida e salva as faces selecionadas
    selected_faces = params[:selected_faces]
    if selected_faces.blank? || selected_faces.reject(&:blank?).empty?
      flash[:alert] = "Por favor, selecione pelo menos uma face do outdoor."
      redirect_to choose_art_home_path
      return
    end

    # Converte para array de inteiros e remove valores vazios
    faces_array = selected_faces.reject(&:blank?).map(&:to_i).uniq.sort
    @outdoor.selected_faces = faces_array

    Rails.logger.info "   ✅ Faces selecionadas: #{faces_array.inspect}"
    Rails.logger.info "   ✅ Total de artes: #{faces_array.size}"

    # 3. Se tem arte própria, processa os uploads
    if @outdoor.has_own_art
      if params[:art_files].present?
        # 🚀 OTIMIZAÇÃO: Valida tamanho dos arquivos antes de processar
        max_file_size = 5.megabytes
        oversized_files = params[:art_files].select { |f| f.size > max_file_size }

        if oversized_files.any?
          flash[:alert] = "Alguns arquivos são muito grandes (máximo 5MB por arquivo). Por favor, reduza o tamanho das imagens."
          redirect_to choose_art_home_path
          return
        end

        # Remove artes antigas antes de adicionar novas
        @outdoor.art_files.purge if @outdoor.art_files.attached?

        # 🚀 OTIMIZAÇÃO: Anexa arquivos em batch (mais rápido)
        valid_files = params[:art_files].select(&:present?)
        @outdoor.art_files.attach(valid_files) if valid_files.any?

        Rails.logger.info "   📎 #{valid_files.size} arte(s) anexada(s)"
      elsif !@outdoor.art_files.attached?
        # Se não tem arquivos anexados e não enviou novos
        flash[:alert] = "Por favor, faça upload das artes para as faces selecionadas."
        redirect_to choose_art_home_path
        return
      end
    else
      # Se não tem arte própria, limpa arquivos anexados
      @outdoor.art_files.purge if @outdoor.art_files.attached?
      Rails.logger.info "   ℹ️  Sem arte própria - artes serão criadas pela equipe"
    end

    # 4. Salva o outdoor
    Rails.logger.info "   🔍 Antes de salvar:"
    Rails.logger.info "      - outdoor_type: #{@outdoor.outdoor_type}"
    Rails.logger.info "      - selected_start_date: #{@outdoor.selected_start_date}"
    Rails.logger.info "      - selected_end_date: #{@outdoor.selected_end_date}"
    Rails.logger.info "      - selected_faces: #{@outdoor.selected_faces.inspect}"
    Rails.logger.info "      - status atual: #{@outdoor.status}"

    if @outdoor.save
      Rails.logger.info "   ✅ Outdoor salvo com sucesso!"
      Rails.logger.info "      - has_own_art: #{@outdoor.has_own_art}"
      Rails.logger.info "      - selected_faces: #{@outdoor.selected_faces.inspect}"
      Rails.logger.info "      - total_arts_count: #{@outdoor.total_arts_count}"
      Rails.logger.info "      - status após save: #{@outdoor.status}"

      # ✅ ATUALIZA O STATUS PARA ART_UPLOADED se as condições forem atendidas
      if @outdoor.outdoor_type.present? &&
         @outdoor.selected_start_date.present? &&
         @outdoor.selected_end_date.present? &&
         @outdoor.selected_faces.present? &&
         @outdoor.selected_faces.any?

        Rails.logger.info "   🚀 Todas condições atendidas! Atualizando status..."
        # Usa o método enum para atualizar o status
        @outdoor.status_art_uploaded!
        Rails.logger.info "   ✅ Status atualizado para: art_uploaded (#{@outdoor.status})"
      else
        Rails.logger.warn "   ⚠️  Condições não atendidas para status art_uploaded:"
        Rails.logger.warn "      - outdoor_type: #{@outdoor.outdoor_type.present?}"
        Rails.logger.warn "      - selected_start_date: #{@outdoor.selected_start_date.present?}"
        Rails.logger.warn "      - selected_end_date: #{@outdoor.selected_end_date.present?}"
        Rails.logger.warn "      - selected_faces.any?: #{@outdoor.selected_faces.present? && @outdoor.selected_faces.any?}"
      end

      @outdoor.reload
      Rails.logger.info "   ✅ Status final após reload: #{@outdoor.status}"

      flash[:notice] = "Arte(s) configurada(s) com sucesso!"
      redirect_to root_path
    else
      Rails.logger.error "   ❌ Erro ao salvar: #{@outdoor.errors.full_messages.join(', ')}"
      flash[:alert] = "Erro ao salvar: #{@outdoor.errors.full_messages.join(', ')}"
      redirect_to choose_art_home_path
    end
  end

  # app/controllers/home_controller.rb

  def post_finalize_budget
    # Verifica se o usuário já possui um orçamento pago
    paid_rent = current_user.rents.where(status: 'paid').first

    if paid_rent.present?
      whatsapp_message = "Olá! Acabei de realizar o pagamento do meu outdoor (Pedido ##{paid_rent.id}). Gostaria de enviar as informações para impressão."
      whatsapp_url = "https://wa.me/5546999776924?text=#{URI.encode_www_form_component(whatsapp_message)}"
      redirect_to whatsapp_url, allow_other_host: true, alert: "Você já possui um pedido pago. Entre em contato via WhatsApp para enviar suas informações."
      return
    end

    # Verifica se o usuário já possui um orçamento pendente
    existing_rent = current_user.rents.where(status: 'pending').first

    if existing_rent.present?
      redirect_to order_status_path(existing_rent.id), alert: "Você já possui um orçamento pendente. Finalize ou cancele-o antes de criar um novo."
      return
    end

    # 🔒 SEGURANÇA: Sempre usa outdoor do current_user (nunca aceita outdoor_id do frontend)
    @outdoor = current_user.outdoor

    unless @outdoor
      redirect_to root_path, alert: "Nenhum outdoor encontrado. Complete o processo de seleção primeiro."
      return
    end

    # Verifica se todas as etapas foram concluídas
    unless @outdoor.outdoor_type.present? && @outdoor.selected_start_date.present? && @outdoor.selected_end_date.present?
      redirect_to root_path, alert: "Complete todas as etapas antes de finalizar o orçamento."
      return
    end

    # 🔒 VALIDAÇÃO: Verifica se as datas foram bloqueadas pelo admin
    end_date = @outdoor.selected_end_date
    if @outdoor.outdoor_location.present? &&
       LocationBlockedDate.location_blocked_for_period?(@outdoor.outdoor_location, @outdoor.selected_start_date, end_date)
      next_available = LocationBlockedDate.minimum_start_date_for_location(@outdoor.outdoor_location)
      redirect_to find_date_home_path, alert: "Este período não está disponível para a localização selecionada. " \
                                              "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}. Por favor, altere a data."
      return
    end

    # ✅ SEGURANÇA: Calcula valor no BACKEND (não aceita do frontend)
    total_amount = BudgetCalculator.calculate_total(@outdoor)

    Rails.logger.info "🔒 Total calculado no backend: R$ #{total_amount}"
    Rails.logger.info "🔒 Outdoor pertence ao usuário: #{current_user.id}"

    # Salva os dados na session (NÃO cria rent ainda)
    session[:pending_checkout] = {
      outdoor_id: @outdoor.id,
      start_date: @outdoor.selected_start_date.to_s,
      end_date: @outdoor.selected_end_date.to_s,
      total_amount: total_amount
    }

    redirect_to new_checkout_path
  end

  def redirect_whatsapp
    # 🔒 SEGURANÇA: Busca apenas nos rents do current_user
    @rent = current_user.rents.find_by(id: params[:id])

    unless @rent
      redirect_to root_path, alert: "Pedido não encontrado."
      return
    end

    # Corrigido: outdoor_type em vez de name (baseado nos seus params)
    mensagem = "Olá! Acabei de pagar o Outdoor #{@rent.outdoor.outdoor_type}. O ID do meu pedido é ##{@rent.id}."

    texto_url = URI.encode_www_form_component(mensagem)
    numero_whatsapp = "5546999776924" # Seu número

    link_wpp = "https://wa.me/#{numero_whatsapp}?text=#{texto_url}"

    redirect_to link_wpp, allow_other_host: true
  end

  private

  def set_outdoor
    @outdoor = current_user.outdoor || current_user.build_outdoor
  end

  def outdoor_params
    params.permit(:outdoor_type, :outdoor_location, :outdoor_size)
  end

  # 🔒 Verifica se as datas salvas no outdoor estão bloqueadas por localização
  def outdoor_dates_blocked?(outdoor)
    return false unless outdoor&.outdoor_location.present? &&
                        outdoor&.selected_start_date.present? &&
                        outdoor&.selected_end_date.present?

    LocationBlockedDate.location_blocked_for_period?(outdoor.outdoor_location, outdoor.selected_start_date, outdoor.selected_end_date)
  end
end

