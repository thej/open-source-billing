module Services
  module Apis
    class ItemApiService

      def self.create(params)
        item = ::Item.new(item_params_api(params))
        ItemApiService.associate_entity(params, item)
        if item.save
          {message: 'Successfully created'}
        else
          {error: item.errors.full_messages}
        end
      end

      def self.update(params)
        item = ::Item.find(params[:id])
        if item.present?
          ItemApiService.associate_entity(params, item)
          if item.update_attributes(item_params_api(params))
            {message: 'Successfully updated'}
          else
            {error: item.errors.full_messages}
          end
        else
          {error: 'Item not found'}
        end
      end

      def self.destroy(params)
        if ::Item.destroy(params)
          {message: 'Successfully deleted'}
        else
          {message: 'Not deleted'}
        end
      end


      def self.associate_entity(params, entity)
        ids, controller = params[:item][:company_ids], params[:controller]

        ActiveRecord::Base.transaction do
          # delete existing associations
          if params[:action] == 'update'
            entities = controller == 'email_templates' ? CompanyEmailTemplate.where(template_id: entity.id) : CompanyEntity.where(entity_id: entity.id, entity_type: entity.class.to_s)
            entities.map(&:destroy) if entities.present?
          end

          # associate item with whole account or selected companies
          if params[:association] == 'account'
            current_user.accounts.first.send(controller) << entity
          else
            ::Company.multiple(ids).each { |company| company.send(controller) << entity } unless ids.blank?
          end
        end

      end

      private

      def self.item_params_api(params)
        ActionController::Parameters.new(params).require(:item).permit(
            :item_name,
            :item_description,
            :unit_cost,
            :quantity,
            :tax_1,
            :tax_2,
            :track_inventory,
            :inventory,
            :archive_number,
            :archived_at,
            :deleted_at,
            :created_at,
            :updated_at,
            :actual_price,
        )
      end

    end
  end
end