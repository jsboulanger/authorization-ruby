require File.join(File.dirname(__FILE__), ".", "spec_helper")


describe Authorization do
  
  before(:all) do
    class MyController
      include Authorization            
    end    
  end
  
  before(:each) do
    MyController.reset_authorizations!
  end
  
  
  describe 'authorize' do
    
    it 'should take a role' do
      MyController.authorize(:admin)
      MyController.authorizations.should include({:roles => [:admin], :options => {}})
    end
    
    it 'should take a role or an array of roles' do
      MyController.authorize([:admin, :manager])
      MyController.authorizations.should include({:roles => [:admin, :manager], :options => {}})
    end
    
    it 'should combine multiple authorization rules' do
      MyController.authorize([:admin])
      MyController.authorize([:manager])
      MyController.authorizations.size.should == 2
    end
    
    it 'should take only option' do
      MyController.authorize([:admin], :only => [:show, :edit])
      MyController.authorizations.should include({:roles => [:admin], :options => {:only => [:show, :edit]}})
      
    end
    
    it 'should take except option' do
      MyController.authorize([:admin], :except => [:index])
      MyController.authorizations.should include({:roles => [:admin], :options => {:except => [:index]}})
    end
    
    it 'should convert options to symbols' do
      MyController.authorize(:admin, :only => ["index"])
      MyController.authorizations.should include({:roles => [:admin], :options => {:only => [:index]}})
    end    
    
  end # authorize
  
  describe 'authorized?' do
    before(:each) do
      MyController.reset_authorizations!
      @user = mock('user')
    end
    
    it 'should return false if there is no authorizations' do
      MyController.authorized?(@user).should be_false      
    end
    
    it 'should return false for nil user' do
      MyController.authorize(:admin)
      MyController.authorized?(nil).should be_false
    end
    
    it 'should return true for nil user if public' do
      MyController.authorize(:public)
      MyController.authorized?(nil).should be_true
    end
    
    it 'should return true if an authorization rule has_role?' do
      MyController.authorize(:admin)
      @user.stub!(:has_role?).and_return true
      MyController.authorized?(@user).should be_true
    end
    
    it 'should call has_role with role' do
      MyController.authorize(:admin)
      @user.should_receive(:has_role?).once.with(:admin).and_return true
      MyController.authorized?(@user)
    end    
    
    it 'should return true if public' do
      MyController.authorize(:public)
      MyController.authorized?(@user).should be_true
    end    
    
    it 'should return true if at least one authorization rule is true'do
      MyController.authorize(:admin)
      MyController.authorize(:public)
      MyController.authorize(:manager)
      MyController.authorized?(@user).should be_true
    end    
    
    describe 'option :only' do
      before(:each) do
        @user.stub!(:has_role?).and_return true
        MyController.authorize(:admin, :only => [:index])        
      end
      
      it 'should not authorize if action is not included' do
        MyController.authorized?(@user, :show).should be_false
      end
      
      it 'should authorize if action is included' do
        MyController.authorized?(@user, :index).should be_true        
      end      
    end # option :only
    
    describe 'option :except' do
      before(:each) do
        @user.stub!(:has_role?).and_return true
        MyController.authorize(:admin, :except => [:index])        
      end
      
      it 'should authorize if action is not included' do
        MyController.authorized?(@user, :show).should be_true
      end
      
      it 'should not authorize if action is included' do
        MyController.authorized?(@user, :index).should be_false
      end      
    end # option :except
    
    
  end # authorized
  
  describe 'ensure_authorized!' do
    before(:each) do
      @controller = MyController.new
      @controller.stub!(:current_user)
      @controller.stub!(:params).and_return({:action => :index})
      @controller.class.stub!(:authorized?).and_return true      
    end
    
    it 'should return true if authorized' do
      @controller.ensure_authorized!.should be_true
    end
    
    it 'should raise Unauthorized if authorization fails' do
      @controller.class.stub!(:authorized?).and_return false
      lambda {
        @controller.ensure_authorized!.should be_true
      }.should raise_error(Authorization::Unauthorized)
        
    end
    
    it "should use 'current_user' to get user" do
      @controller.should_receive(:current_user)
      @controller.ensure_authorized!
    end
    
    it "should use 'params[:action]' to get action" do
      params = mock('params')
      params.should_receive(:[]).with(:action)
      @controller.should_receive(:params).and_return params
      @controller.ensure_authorized!
    end
  end # ensure_authorized!
    
end # Authorization