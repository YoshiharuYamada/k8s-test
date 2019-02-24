class BlogsController < ApplicationController
  before_action :set_blog, only: %i[show edit update destroy]

  def index
    @blogs = Blog.all
  end

  def show; end

  def new
    @blog = Blog.new
  end

  def edit; end

  def create
    @blog = Blog.new(blog_params)
    if @blog.save
      EchoJob.perform_later(@blog)
      redirect_to blogs_path, notice: 'Blog was successfully created.'
    else
      render :new
    end
  end

  def update
    if @blog.update(blog_params)
      EchoJob.perform_later(@blog)
      redirect_to blogs_path, notice: 'Blog was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @blog.destroy
    redirect_to blogs_path, notice: 'Blog was successfully destroyed.'
  end

  private

  def set_blog
    @blog = Blog.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :body)
  end
end
